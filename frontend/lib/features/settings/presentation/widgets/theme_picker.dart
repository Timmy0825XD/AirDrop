import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import 'theme_preview.dart';

/// Elegir el tema con vista previa (RF-52): las tres opciones muestran en
/// miniatura cómo quedaría la app. Tocar una solo cambia la elección; el
/// tema de la app cambia al tocar "Aplicar".
class ThemePicker extends StatelessWidget {
  const ThemePicker({
    super.key,
    required this.applied,
    required this.picked,
    required this.onPick,
    required this.onApply,
  });

  /// El tema que tiene la app ahora.
  final ThemeMode applied;

  /// El que la persona está mirando en la vista previa.
  final ThemeMode picked;
  final ValueChanged<ThemeMode> onPick;
  final VoidCallback onApply;

  static const _options = [
    (ThemeMode.light, 'Claro'),
    (ThemeMode.dark, 'Oscuro'),
    (ThemeMode.system, 'Automático'),
  ];

  @override
  Widget build(BuildContext context) {
    final pending = picked != applied;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ThemeOptions(picked: picked, onPick: onPick),
          const SizedBox(height: 12),
          Text(
            pending
                ? 'Así se vería. Toca Aplicar para cambiarlo.'
                : applied == ThemeMode.system
                ? 'Automático sigue el tema de tu teléfono.'
                : applied == ThemeMode.dark
                ? 'Tema oscuro aplicado.'
                : 'Tema claro aplicado.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: pending ? onApply : null,
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptions extends StatelessWidget {
  const _ThemeOptions({required this.picked, required this.onPick});
  final ThemeMode picked;
  final ValueChanged<ThemeMode> onPick;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final stacked =
          box.maxWidth < 340 && MediaQuery.textScalerOf(context).scale(16) > 24;
      final options = [
        for (final (mode, label) in ThemePicker._options)
          ThemeOption(
            mode: mode,
            label: label,
            selected: mode == picked,
            onTap: () => onPick(mode),
          ),
      ];
      return stacked
          ? Column(children: options)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final option in options) Expanded(child: option)],
            );
    },
  );
}
