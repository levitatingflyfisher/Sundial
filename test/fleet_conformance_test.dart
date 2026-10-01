// Sundial's entire fleet-standardization posture, in one place.
// Every deliberate divergence from fleet canon is a recorded field here —
// see package:oh_fleet_conformance for what each check enforces.
import 'package:oh_fleet_conformance/oh_fleet_conformance.dart';

void main() => runFleetConformance(const FleetAppConfig(
      appId: 'sundial',
      // Bundles its type via openhearth_design's package fonts, so nothing
      // falls back to a web font — a character the bundled families cannot
      // draw is a box on a real phone. C7 sweeps lib/ for any.
      // C8: a bare IconButton.filled/.filledTonal would paint its glyph in
      // ohStyle's ambient iconTheme color — the exact fill color of the
      // button itself. Filled icon buttons must come from OhIconButton.
      checks: {
        // C13: the PWA loads nothing from Google's CDNs. web/flutter_bootstrap.js
        // points CanvasKit and the engine's fallback fonts at this origin.
        FleetCheck.c13WebSelfHosted,
        ...FleetAppConfig.withBundledFonts,
        FleetCheck.c8IconButtons,
        // C10: no raw exception text on screen; failures go through
        // OhErrorState / ohFriendlyErrorMessage and the raw error is logged.
        FleetCheck.c10RawErrors,
        // C11: every app-bar action says what it does in words (the theme
        // toggle is icon plus word; Save actions are text buttons).
        FleetCheck.c11IconLabels,
        // C9: every routed screen has a way in (the Rich tabs navigate from
        // the shell's tab list, which C9 reads as path literals).
        FleetCheck.c9Routes,
        // C12: the accent must not be the error red (ΔE2000 ≥ 12).
        FleetCheck.c12AccentVsError,
        // Item 24: the screens below are swept at 360dp × 1.3 in
        // test/a11y/primary_action_sweep_test.dart.
        FleetCheck.c5PrimaryScreens,
      },
      primaryActionScreens: {'TimerScreen', 'FlowScreen', 'ManualEntrySheet'},
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
