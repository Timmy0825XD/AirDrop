import 'package:flutter/material.dart';
import '../../data/app_settings.dart';

class SettingsActions {
  const SettingsActions({
    required this.onPick,
    required this.onApply,
    required this.onTextSize,
    required this.onContrast,
    required this.onMotion,
    required this.onSimpleMode,
  });
  final ValueChanged<ThemeMode> onPick;
  final VoidCallback onApply;
  final ValueChanged<TextSize> onTextSize;
  final ValueChanged<bool> onContrast, onMotion, onSimpleMode;
}
