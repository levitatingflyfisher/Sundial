package com.openhearth.sundial

import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationManagerCompat

/**
 * Hosts the timer notification in a foreground service so Android doesn't
 * kill it when the Flutter process goes to background. The chronometer in the
 * notification is self-updating (wall-clock based) so the service itself does
 * no ticking — it only exists to keep the notification alive and promote the
 * app's priority while the timer runs.
 *
 * SHOW_* intents are dispatched from [MainActivity]'s MethodChannel handler
 * when Flutter calls showRunning / showPaused / dismiss. TOGGLE_* intents
 * are dispatched from [MediaActionReceiver] when the user taps an action on
 * the lockscreen / media-style notification. On each TOGGLE, the service:
 *  1. Updates SharedPreferences (fallback for cold-start reconciliation).
 *  2. Calls [pushActionToDart] via [MainActivity.sharedMethodChannel] to
 *     deliver the action to Dart immediately (primary path when engine alive).
 */
class TimerForegroundService : Service() {

    companion object {
        const val ACTION_SHOW_RUNNING = "com.openhearth.sundial.service.SHOW_RUNNING"
        const val ACTION_SHOW_PAUSED = "com.openhearth.sundial.service.SHOW_PAUSED"
        const val ACTION_DISMISS = "com.openhearth.sundial.service.DISMISS"
        const val ACTION_TOGGLE_PAUSE = "com.openhearth.sundial.service.TOGGLE_PAUSE"
        const val ACTION_TOGGLE_RESUME = "com.openhearth.sundial.service.TOGGLE_RESUME"
        const val ACTION_TOGGLE_STOP = "com.openhearth.sundial.service.TOGGLE_STOP"

        const val EXTRA_PROFILE_ID = "profileId"
        const val EXTRA_EFFECTIVE_ORIGIN_MS = "effectiveOriginMs"
        const val EXTRA_ACCUMULATED_SECS = "accumulatedSecs"
        const val EXTRA_DURATION_MS = "durationMs"

        // Flutter shared_preferences plugin stores values under this file
        // with a "flutter." key prefix. Must match TimerNotifier's keys.
        private const val FLUTTER_PREFS_FILE = "FlutterSharedPreferences"
        private const val KEY_START_MS = "flutter.timer_start_ms"
        private const val KEY_ACC_SECS = "flutter.timer_paused_accumulated_secs"
    }

    private var currentProfileId: String? = null
    // Cached state of the currently displayed notification. Exactly one of
    // these is non-null at any time (running → origin; paused → accumulated;
    // dismissed → both null).
    private var cachedEffectiveOriginMs: Long? = null
    private var cachedAccumulatedSecs: Int? = null
    private var cachedDurationMs: Long = 7_200_000L

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val session = TimerMediaSession.get(applicationContext)
        when (intent?.action) {
            ACTION_SHOW_RUNNING -> {
                val profileId = intent.getStringExtra(EXTRA_PROFILE_ID) ?: "default"
                val effectiveOriginMs = intent.getLongExtra(
                    EXTRA_EFFECTIVE_ORIGIN_MS,
                    System.currentTimeMillis(),
                )
                val durationMs = intent.getLongExtra(EXTRA_DURATION_MS, 7_200_000L)
                val (notifId, notification) =
                    session.buildRunningNotification(profileId, effectiveOriginMs, durationMs)
                goForeground(notifId, notification)
                currentProfileId = profileId
                cachedEffectiveOriginMs = effectiveOriginMs
                cachedAccumulatedSecs = null
                cachedDurationMs = durationMs
            }
            ACTION_SHOW_PAUSED -> {
                val profileId = intent.getStringExtra(EXTRA_PROFILE_ID) ?: "default"
                val accumulatedSecs = intent.getIntExtra(EXTRA_ACCUMULATED_SECS, 0)
                val durationMs = intent.getLongExtra(EXTRA_DURATION_MS, 7_200_000L)
                val (notifId, notification) =
                    session.buildPausedNotification(profileId, accumulatedSecs, durationMs)
                goForeground(notifId, notification)
                currentProfileId = profileId
                cachedEffectiveOriginMs = null
                cachedAccumulatedSecs = accumulatedSecs
                cachedDurationMs = durationMs
            }
            ACTION_TOGGLE_PAUSE -> handleTogglePause(intent, session)
            ACTION_TOGGLE_RESUME -> handleToggleResume(intent, session)
            ACTION_TOGGLE_STOP -> handleToggleStop(intent, session)
            ACTION_DISMISS -> {
                val profileId =
                    intent.getStringExtra(EXTRA_PROFILE_ID) ?: currentProfileId
                // Remove the notification FIRST (via the service's foreground
                // state), then release the media session — the notification
                // references the session token, so releasing before removal
                // can leave a stale notification.
                stopForeground(STOP_FOREGROUND_REMOVE)
                if (profileId != null) {
                    NotificationManagerCompat.from(applicationContext)
                        .cancel(session.notifId(profileId))
                    session.releaseSession(profileId)
                }
                currentProfileId = null
                cachedEffectiveOriginMs = null
                cachedAccumulatedSecs = null
                stopSelf()
            }
            else -> {
                // Null-action restart after process death: nothing to show,
                // just stop so we don't linger as an orphaned foreground.
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    /**
     * Flip the notification to the paused view immediately, regardless of
     * whether Dart is alive. Also writes Flutter's paused-state keys so
     * cold-start reconstruction honors the moment the user tapped Pause.
     */
    private fun handleTogglePause(intent: Intent, session: TimerMediaSession) {
        val profileId = intent.getStringExtra(EXTRA_PROFILE_ID) ?: currentProfileId ?: return
        val origin = cachedEffectiveOriginMs ?: return
        val accumulatedSecs =
            ((System.currentTimeMillis() - origin) / 1000L).toInt().coerceAtLeast(0)
        val (notifId, notification) =
            session.buildPausedNotification(profileId, accumulatedSecs, cachedDurationMs)
        goForeground(notifId, notification)
        writeDartPausedState(accumulatedSecs)
        currentProfileId = profileId
        cachedEffectiveOriginMs = null
        cachedAccumulatedSecs = accumulatedSecs
        pushActionToDart("pause", profileId)
    }

    private fun handleToggleResume(intent: Intent, session: TimerMediaSession) {
        val profileId = intent.getStringExtra(EXTRA_PROFILE_ID) ?: currentProfileId ?: return
        val accumulated = cachedAccumulatedSecs ?: return
        val nowMs = System.currentTimeMillis()
        val newOriginMs = nowMs - accumulated * 1000L
        val (notifId, notification) =
            session.buildRunningNotification(profileId, newOriginMs, cachedDurationMs)
        goForeground(notifId, notification)
        writeDartResumedState(nowMs, accumulated)
        currentProfileId = profileId
        cachedEffectiveOriginMs = newOriginMs
        cachedAccumulatedSecs = null
        pushActionToDart("resume", profileId)
    }

    private fun handleToggleStop(intent: Intent, session: TimerMediaSession) {
        val profileId = intent.getStringExtra(EXTRA_PROFILE_ID) ?: currentProfileId
        // pushActionToDart("stop") tells Dart to call stopAndSave
        // immediately when the engine is alive. SharedPrefs stop flag
        // (written by MediaActionReceiver) is the fallback for cold-start
        // reconciliation when the engine was dead at tap time.
        stopForeground(STOP_FOREGROUND_REMOVE)
        if (profileId != null) {
            NotificationManagerCompat.from(applicationContext)
                .cancel(session.notifId(profileId))
            session.releaseSession(profileId)
        }
        pushActionToDart("stop", profileId ?: "default")
        currentProfileId = null
        cachedEffectiveOriginMs = null
        cachedAccumulatedSecs = null
        stopSelf()
    }

    /**
     * Best-effort push to Dart. When the Flutter engine is alive,
     * [MainActivity.sharedMethodChannel] is non-null and the invocation
     * lands in main.dart's handler. When dead, this is a no-op and the
     * SharedPrefs flags serve as fallback.
     */
    private fun pushActionToDart(action: String, profileId: String) {
        try {
            MainActivity.sharedMethodChannel?.invokeMethod(
                "timerAction",
                mapOf("action" to action, "profileId" to profileId),
            )
        } catch (_: Exception) {
            // Engine not alive — SharedPrefs flags are the fallback.
        }
    }

    /** Writes Flutter's SharedPreferences to mirror Dart's `pause()`. */
    private fun writeDartPausedState(accumulatedSecs: Int) {
        applicationContext
            .getSharedPreferences(FLUTTER_PREFS_FILE, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_START_MS)
            .putLong(KEY_ACC_SECS, accumulatedSecs.toLong())
            .commit()
    }

    /** Writes Flutter's SharedPreferences to mirror Dart's `resume()`. */
    private fun writeDartResumedState(nowMs: Long, accumulatedSecs: Int) {
        applicationContext
            .getSharedPreferences(FLUTTER_PREFS_FILE, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_START_MS, nowMs)
            .putLong(KEY_ACC_SECS, accumulatedSecs.toLong())
            .commit()
    }

    private fun goForeground(notifId: Int, notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                notifId,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(notifId, notification)
        }
    }
}
