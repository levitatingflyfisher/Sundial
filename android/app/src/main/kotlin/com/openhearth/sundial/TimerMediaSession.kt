package com.openhearth.sundial

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat.MediaStyle

/**
 * Builds the running / paused timer notifications and owns the backing
 * [MediaSessionCompat]s. Notifications are posted by [TimerForegroundService]
 * via `startForeground()` — this class no longer calls NotificationManager
 * directly, because an ongoing, user-controllable timer notification must be
 * tied to a foreground service on modern Android.
 */
class TimerMediaSession private constructor(private val context: Context) {

    companion object {
        @Volatile private var instance: TimerMediaSession? = null
        fun get(context: Context): TimerMediaSession =
            instance ?: synchronized(this) {
                instance ?: TimerMediaSession(context.applicationContext).also { instance = it }
            }

        const val CHANNEL_ID = "sundial_timer"
        private const val TIMER_ACTION = "com.openhearth.sundial.TIMER_ACTION"
    }

    private val mediaSessions = mutableMapOf<String, MediaSessionCompat>()

    init {
        createChannel()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Timer", NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Sundial timer status"
                setShowBadge(false)
            }
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    fun notifId(profileId: String): Int =
        if (profileId == "default") 42001 else (profileId.hashCode() and 0x7FFFFFFF) + 42002

    private fun ensureSession(profileId: String): MediaSessionCompat =
        mediaSessions.getOrPut(profileId) {
            MediaSessionCompat(context, "SundialTimer:$profileId").apply {
                isActive = true
                setCallback(object : MediaSessionCompat.Callback() {
                    override fun onPause() = sendAction(profileId, "pause")
                    override fun onPlay() = sendAction(profileId, "resume")
                    override fun onStop() = sendAction(profileId, "stop")
                })
            }
        }

    private fun sendAction(profileId: String, action: String) {
        val intent = Intent(context, MediaActionReceiver::class.java).apply {
            this.action = TIMER_ACTION
            putExtra("profileId", profileId)
            putExtra("action", action)
        }
        context.sendBroadcast(intent)
    }

    private fun formatElapsed(totalSecs: Int): String {
        val h = totalSecs / 3600
        val m = (totalSecs % 3600) / 60
        val s = totalSecs % 60
        return if (h > 0) "%d:%02d:%02d".format(h, m, s) else "%d:%02d".format(m, s)
    }

    /** Builds the running notification and returns (notifId, notification). */
    fun buildRunningNotification(
        profileId: String,
        effectiveOriginMs: Long,
        durationMs: Long = 7_200_000L,
    ): Pair<Int, Notification> {
        val session = ensureSession(profileId)
        val elapsedMs = System.currentTimeMillis() - effectiveOriginMs
        val elapsedSecs = (elapsedMs / 1000).toInt().coerceAtLeast(0)
        val display = formatElapsed(elapsedSecs)

        session.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, "Sundial")
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, "Timer running")
                .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)
                .build()
        )
        session.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setState(PlaybackStateCompat.STATE_PLAYING, elapsedMs, 1.0f)
                .setActions(PlaybackStateCompat.ACTION_PAUSE or PlaybackStateCompat.ACTION_STOP)
                .build()
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Sundial")
            .setContentText(display)
            .setContentIntent(openAppIntent())
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setWhen(effectiveOriginMs)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(android.R.drawable.ic_media_pause, "Pause", actionIntent(profileId, "pause"))
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", actionIntent(profileId, "stop"))
            .setStyle(
                MediaStyle()
                    .setMediaSession(session.sessionToken)
                    .setShowActionsInCompactView(0, 1)
            )
            .build()

        return notifId(profileId) to notification
    }

    /** Builds the paused notification and returns (notifId, notification). */
    fun buildPausedNotification(
        profileId: String,
        accumulatedSecs: Int,
        durationMs: Long = 7_200_000L,
    ): Pair<Int, Notification> {
        val session = ensureSession(profileId)
        val display = formatElapsed(accumulatedSecs)

        session.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, "Sundial — paused")
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, display)
                .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)
                .build()
        )
        session.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setState(PlaybackStateCompat.STATE_PAUSED, accumulatedSecs * 1000L, 0.0f)
                .setActions(PlaybackStateCompat.ACTION_PLAY or PlaybackStateCompat.ACTION_STOP)
                .build()
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Sundial — paused")
            .setContentText(display)
            .setContentIntent(openAppIntent())
            .setOngoing(true)
            .setAutoCancel(false)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .addAction(android.R.drawable.ic_media_play, "Resume", actionIntent(profileId, "resume"))
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", actionIntent(profileId, "stop"))
            .setStyle(
                MediaStyle()
                    .setMediaSession(session.sessionToken)
                    .setShowActionsInCompactView(0, 1)
            )
            .build()

        return notifId(profileId) to notification
    }

    /**
     * Releases the MediaSession for a profile. Call this after the service
     * removes the notification, not before — the notification references the
     * session's token.
     */
    fun releaseSession(profileId: String) {
        mediaSessions.remove(profileId)?.apply {
            isActive = false
            release()
        }
    }

    private fun openAppIntent(): PendingIntent = PendingIntent.getActivity(
        context, 0,
        Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        },
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )

    private fun actionIntent(profileId: String, action: String): PendingIntent {
        val intent = Intent(context, MediaActionReceiver::class.java).apply {
            this.action = TIMER_ACTION
            putExtra("profileId", profileId)
            putExtra("action", action)
        }
        val requestCode = "$profileId:$action".hashCode()
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }
}
