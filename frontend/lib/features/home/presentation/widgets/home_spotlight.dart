import 'package:flutter/material.dart';

import '../../../../core/widgets/count_up_text.dart';
import '../../../../core/widgets/drone_art.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/radar_sweep.dart';
import '../../../../core/widgets/ring_gauge.dart';
import '../../../../theme/app_palette.dart';

/// La cifra principal de un inicio, como la pantalla de un centro de
/// control: en una tarjeta, el dron flotando sobre un radar que barre, su
/// estado en una pastilla y, separado por una línea fina, el número grande
/// con su etiqueta en dos líneas.
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
      child: GlassCard(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RadarStage(status: status),
            const SizedBox(height: 14),
            _Figure(value: value, label: label, progress: progress),
          ],
        ),
      ),
    );
  }
}

/// El radar al fondo, el dron encima y la pastilla del estado abajo.
class _RadarStage extends StatelessWidget {
  const _RadarStage({this.status});

  final Widget? status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(bottom: 18, child: RadarSweep(reach: 0.42)),
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: DroneArt(width: 230),
          ),
          if (status != null) Positioned(bottom: 0, child: status!),
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
        padding: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.palette.glassBorder)),
        ),
        child: Row(
          children: [
            CountUpText(
              value: value,
              style: theme.textTheme.displayMedium?.copyWith(
                letterSpacing: -2,
                height: 1,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(height: 1.4),
              ),
            ),
            if (progress != null) RingGauge(progress: progress!, size: 46),
          ],
        ),
      ),
    );
  }
}
