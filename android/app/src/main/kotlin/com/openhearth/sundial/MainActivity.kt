package com.openhearth.sundial

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        /** Accessible from [TimerForegroundService] to push timer actions to Dart. */
        @Volatile
        var sharedMethodChannel: MethodChannel? = null
    }

    private val channelName = "com.openhearth.sundial/media_session"
    private var methodChannel: MethodChannel? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // An already-running MainActivity gets re-delivered here when the
        // widget tap launches the app via SINGLE_TOP|CLEAR_TOP. Re-check the
        // extra so Dart can flip into Flow mode.
        setIntent(intent)
        dispatchLaunchSource(intent)
    }

    private fun dispatchLaunchSource(intent: Intent?) {
        val source = intent?.getStringExtra("launch_source") ?: return
        methodChannel?.invokeMethod("launchSource", mapOf("source" to source))
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        sharedMethodChannel = methodChannel
        methodChannel!!
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= 33) {
                            requestPermissions(
                                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 0
                            )
                        }
                        result.success(null)
                    }
                    "showRunning" -> {
                        val profileId = call.argument<String>("profileId") ?: "default"
                        val startTimeMs = (call.argument<Any>("startTimeMs") as? Number)?.toLong() ?: 0L
                        val accumulatedMs = (call.argument<Any>("accumulatedMs") as? Number)?.toLong() ?: 0L
                        val durationMs = (call.argument<Any>("durationMs") as? Number)?.toLong() ?: 7_200_000L
                        val intent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_SHOW_RUNNING
                            putExtra(TimerForegroundService.EXTRA_PROFILE_ID, profileId)
                            putExtra(
                                TimerForegroundService.EXTRA_EFFECTIVE_ORIGIN_MS,
                                startTimeMs - accumulatedMs,
                            )
                            putExtra(TimerForegroundService.EXTRA_DURATION_MS, durationMs)
                        }
                        startForegroundServiceCompat(intent)
                        result.success(null)
                    }
                    "showPaused" -> {
                        val profileId = call.argument<String>("profileId") ?: "default"
                        val accumulatedSecs = call.argument<Int>("accumulatedSecs") ?: 0
                        val durationMs = (call.argument<Any>("durationMs") as? Number)?.toLong() ?: 7_200_000L
                        val intent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_SHOW_PAUSED
                            putExtra(TimerForegroundService.EXTRA_PROFILE_ID, profileId)
                            putExtra(TimerForegroundService.EXTRA_ACCUMULATED_SECS, accumulatedSecs)
                            putExtra(TimerForegroundService.EXTRA_DURATION_MS, durationMs)
                        }
                        startForegroundServiceCompat(intent)
                        result.success(null)
                    }
                    "dismiss" -> {
                        val profileId = call.argument<String>("profileId") ?: "default"
                        val intent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_DISMISS
                            putExtra(TimerForegroundService.EXTRA_PROFILE_ID, profileId)
                        }
                        // Use regular startService for dismiss — the service
                        // is expected to call stopForeground+stopSelf, and
                        // startForegroundService would require another
                        // startForeground() call before timeout.
                        startService(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Cold-start widget tap: the extra is already on the activity's
        // intent. Fire the dispatch once the channel is wired so Dart sees
        // it on the first frame.
        dispatchLaunchSource(intent)
    }

    override fun onDestroy() {
        sharedMethodChannel = null
        methodChannel = null
        super.onDestroy()
    }

    private fun startForegroundServiceCompat(intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
