// Sundial's entire fleet-standardization posture, in one place.
// Every deliberate divergence from fleet canon is a recorded field here —
// see package:oh_fleet_conformance for what each check enforces.
import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';

void main() => runFleetConformance(const FleetAppConfig(
      appId: 'sundial',
      // Bundles its own type, so nothing falls back to a web font — a
      // character the bundled families cannot draw is a box on a
      // real phone. C7 sweeps lib/ for any.
      checks: FleetAppConfig.withBundledFonts,
      // Tier T: local ThemeData built over openhearth_design tokens
      // (OhColors aliases + OhTypography.materialTextTheme), not OhTheme.
      styleTier: StyleTier.tokens,
      androidPermissions: {
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.VIBRATE',
        // Exercised, not vestigial: TimerForegroundService runs the outdoor
        // timer as a mediaPlayback foreground service (lock-screen controls,
        // survives backgrounding) — evidence recorded in AndroidManifest.xml.
        'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
      },
      // C4 v2 — the release MERGED surface: source permissions plus
      // what plugins and the manifest merge inject. Bites when an APK
      // build has left a merged manifest under build/ (dev box).
      mergedAndroidPermissions: {
        'android.permission.ACCESS_NETWORK_STATE',
        'android.permission.FOREGROUND_SERVICE',
        'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.RECEIVE_BOOT_COMPLETED',
        'android.permission.VIBRATE',
        'android.permission.WAKE_LOCK',
        'com.openhearth.sundial.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
      },
    ));
