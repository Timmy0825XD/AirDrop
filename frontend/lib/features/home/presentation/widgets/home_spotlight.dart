import 'package:flutter/material.dart';

import '../../../../core/widgets/count_up_text.dart';
import '../../../../core/widgets/drone_art.dart';
import '../../../../core/widgets/ring_gauge.dart';
import '../../../../theme/app_palette.dart';

/// La cifra principal de un inicio, como en un tablero de vuelo: el dron
/// flotando, su estado en una pastilla y debajo el número grande con su
/// etiqueta en dos líneas, subrayado por la línea de acento.
class HomeSpotlight extends StatelessWidget {
  const HomeSpotlight({
    super.key,
    required this.value,
    required this.label,
    this.status,
    this.progress,
  });

  /// `null` pinta un guion mientras carga.
  final int? value;

  /// Dos líneas ("Pedidos\nen curso"); se pinta en mayúsculas.
  final String label;
  final Widget? status;

  /// Llena el anillo de al lado (0 a 1); sin él, no hay anillo.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final spoken = label.replaceAll('\n', ' ');
    return Semantics(
      label: '$spoken: ${value ?? 'sin dato'}',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: Center(child: DroneArt(width: 250)),
              ),
              ?status,
            ],
          ),
          const SizedBox(height: 18),
          _Figure(value: value, label: label, progress: progress),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label, this.progress});

  final int? value;
  final String label;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: context.palette.accentGradient.first,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            if (progress != null) ...[
              RingGauge(progress: progress!, size: 44),
              const SizedBox(width: 14),
            ],
            CountUpText(value: value, style: theme.textTheme.displayMedium),
            const SizedBox(width: 10),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
