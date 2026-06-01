package com.openhearth.sundial

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Handles lockscreen / media-style notification action taps. Three things
 * happen on every tap:
 *
 * 1. A SharedPreferences flag is written (`.commit()` for durability) as a
 *    fallback so cold-start reconciliation produces the right TimerState
 *    if the Flutter engine was dead at tap time.
 * 2. A TOGGLE intent is dispatched to [TimerForegroundService] so the
 *    notification flips visually immediately, even if the Flutter engine is
 *    dead (e.g. after the user swiped the app from recents).
 * 3. The service calls [pushActionToDart] via [MainActivity.sharedMethodChannel]
 *    to deliver the action to Dart immediately when the engine is alive —
 *    this is the primary path; the SharedPrefs flag in (1) is the fallback.
 */
class MediaActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val profileId = intent.getStringExtra("profileId") ?: "default"
        val action = intent.getStringExtra("action") ?: return

        // Keys must match Flutter's shared_preferences format: "flutter.<key>"
        // For the default profile, use legacy keys (backward compatible with old installs).
        // For other profiles, use namespaced keys.
        val (baseKey, serviceAction) = when (action) {
            "stop" -> "notif_pending_stop" to TimerForegroundService.ACTION_TOGGLE_STOP
            "pause" -> "notif_pending_pause" to TimerForegroundService.ACTION_TOGGLE_PAUSE
            "resume" -> "notif_pending_resume" to TimerForegroundService.ACTION_TOGGLE_RESUME
            else -> return
        }
        val flutterKey = if (profileId == "default") "flutter.$baseKey"
                         else "flutter.${baseKey}_$profileId"

        // Use commit() (synchronous) rather than apply() — BroadcastReceivers
        // have a short lifetime and the app process may be killed immediately
        // after this returns. apply() could lose the write before it flushes.
        context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit()
            .putBoolean(flutterKey, true)
            .commit()

        // Dispatch to the foreground service so the notification flips
        // immediately — critical when Dart is dead (app swiped from
        // recents). Using regular startService is correct: the service is
        // already in foreground, and startForegroundService would require
        // another startForeground() call within the 5s timeout.
        val serviceIntent = Intent(context, TimerForegroundService::class.java).apply {
            this.action = serviceAction
            putExtra(TimerForegroundService.EXTRA_PROFILE_ID, profileId)
        }
        context.startService(serviceIntent)
    }
}
