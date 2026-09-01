// lib/shared/widgets/theme_toggle.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:sundial/core/providers/core_providers.dart';

/// The one theme control: light, dark or follow the phone, in the app bar of
/// every primary screen (fleet theme ruling). Icon plus a short word, and a
/// menu that names each choice, so any mode is at most two taps away.
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(userPrefsProvider).valueOrNull?.themeMode ??
        OhThemeModePreference.defaultValue;
    return OhThemeToggle(
      value: value,
      onChanged: (mode) =>
          ref.read(settingsRepositoryProvider).setThemeMode(mode),
    );
  }
}
