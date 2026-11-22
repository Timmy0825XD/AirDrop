import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/app_settings.dart';
import 'widgets/settings_actions.dart';
import 'widgets/settings_page.dart';

/// El tema espera a Aplicar; los demás ajustes se guardan al tocarlos.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  ThemeMode? _picked;
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final control = ref.read(settingsProvider.notifier);
    final role = ref.watch(authControllerProvider).value?.user?.role;
    return SettingsPage(
      settings: settings,
      picked: _picked ?? settings.themeMode,
      role: role,
      actions: SettingsActions(
        onPick: (mode) => setState(() => _picked = mode),
        onApply: () {
          if (_picked == null) return;
          control.setThemeMode(_picked!);
          setState(() => _picked = null);
        },
        onTextSize: control.setTextSize,
        onContrast: control.setHighContrast,
        onMotion: control.setReduceMotion,
        onSimpleMode: control.setSimpleMode,
      ),
    );
  }
}
