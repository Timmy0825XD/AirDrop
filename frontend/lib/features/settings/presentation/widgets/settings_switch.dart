import 'package:flutter/material.dart';

/// Un ajuste de sí o no: el título, qué hace en una línea y el interruptor.
/// Toda la fila se toca, y el lector de pantalla la oye como un interruptor
/// con su estado.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      secondary: icon == null ? null : Icon(icon, size: 24),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      value: value,
      onChanged: onChanged,
    );
  }
}
