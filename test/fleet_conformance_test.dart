// Sundial's entire fleet-standardization posture, in one place.
// Every deliberate divergence from fleet canon is a recorded field here —
// see package:oh_fleet_conformance for what each check enforces.
import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';

void main() => runFleetConformance(const FleetAppConfig(
      appId: 'sundial',
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
    ));
