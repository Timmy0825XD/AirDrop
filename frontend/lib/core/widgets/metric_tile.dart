import 'package:flutter/material.dart';

import 'count_up_text.dart';
import 'glass_card.dart';

/// Una cifra en una tarjeta de vidrio: la etiqueta en mayúsculas, el
/// número grande que cuenta al aparecer y una línea de contexto. Con
/// [onTap] lleva a la lista de donde sale el número.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.caption,
    this.color,
    this.onTap,
    this.footer,
  });

  final String label;

  /// `null` pinta un guion: el dato no ha llegado o falló.
  final int? value;
  final String? unit;
  final String? caption;

  /// Color de la cifra; por defecto, el del texto.
  final Color? color;
  final VoidCallback? onTap;

  /// Lo que va debajo de la cifra (barra de segmentos, mini gráfico).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: ${value ?? 'sin dato'} ${unit ?? ''}',
      button: onTap != null,
      excludeSemantics: true,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(height: 8),
            _Figure(value: value, unit: unit, color: color),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(caption!, style: theme.textTheme.bodySmall, maxLines: 2),
            ],
            if (footer != null) ...[const SizedBox(height: 10), footer!],
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, this.unit, this.color});

  final int? value;
  final String? unit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        CountUpText(
          value: value,
          style: theme.textTheme.displaySmall?.copyWith(color: color),
        ),
        if (unit != null) ...[
          const SizedBox(width: 4),
          Text(
            unit!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
