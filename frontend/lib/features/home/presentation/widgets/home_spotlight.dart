import 'package:flutter/material.dart';

import '../../../../core/widgets/count_up_text.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/ring_gauge.dart';

/// La cifra principal de un inicio en una tarjeta: el estado en una
/// pastilla, el número grande que cuenta al aparecer y su etiqueta al lado.
/// Con [progress] lleva un anillo a la derecha. Con [onTap] se toca para
/// abrir lo que cuenta.
class HomeSpotlight extends StatelessWidget {
  const HomeSpotlight({
    super.key,
    required this.value,
    required this.label,
    this.status,
    this.progress,
    this.onTap,
  });

  /// `null` pinta un guion mientras carga.
  final int? value;

  /// La etiqueta ("Urgencias en cola"); un salto de línea se respeta.
  final String label;
  final Widget? status;

  /// Llena el anillo de al lado (0 a 1); sin él, no hay anillo.
  final double? progress;

  /// Abre la lista que cuenta la cifra ("Pedidos en curso" → Mis pedidos).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final spoken = label.replaceAll('\n', ' ');
    return Semantics(
      label: '$spoken: ${value ?? 'sin dato'}',
      container: true,
      button: onTap != null,
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ?status,
              if (status != null) const SizedBox(height: 12),
              _Figure(value: value, label: label, progress: progress),
            ],
          ),
        ),
      ),
    );
  }
}

/// El número grande, la etiqueta en gris y, si hay, el anillo.
class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label, this.progress});

  final int? value;
  final String label;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CountUpText(
          value: value,
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: 44,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ),
        if (progress != null) RingGauge(progress: progress!, size: 44),
      ],
    );
  }
}
