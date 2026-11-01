import 'package:flutter/material.dart';

import '../../../../../core/widgets/drone_mark.dart';
import '../../../../../core/widgets/radar_sweep.dart';
import '../../../../../theme/app_palette.dart';

/// Arriba del formulario de urgencia, como la pantalla de un despacho: un
/// radar que barre a la izquierda y, a la derecha, cómo se resuelve la
/// urgencia. La central con stock la elige el despachador al autorizar y
/// sale un Wingcopter 198 disponible; no promete ni central ni tiempos
/// antes de tiempo.
class EmergencyBanner extends StatelessWidget {
  const EmergencyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.onSurface.withValues(alpha: 0.07),
            theme.colorScheme.onSurface.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.glassBorder),
      ),
      child: const Row(
        children: [
          SizedBox.square(dimension: 108, child: _Scope()),
          SizedBox(width: 14),
          Expanded(child: _Plan()),
        ],
      ),
    );
  }
}

/// El radar con el punto de tu ubicación al centro.
class _Scope extends StatelessWidget {
  const _Scope();

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned.fill(
          child: RadarSweep(reach: 0.5, period: Duration(milliseconds: 2600)),
        ),
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: ink,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: ink.withValues(alpha: 0.5), blurRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}

/// La búsqueda y el dron que sale.
class _Plan extends StatelessWidget {
  const _Plan();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final muted = theme.textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BÚSQUEDA',
          style: theme.textTheme.labelSmall?.copyWith(color: palette.success),
        ),
        const SizedBox(height: 4),
        Text(
          'Central con stock más cercana',
          style: theme.textTheme.titleSmall,
        ),
        Text('La elige el despachador al autorizar', style: muted),
        Divider(height: 18, color: palette.glassBorder),
        Row(
          children: [
            const DroneMark(size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wingcopter 198', style: theme.textTheme.labelLarge),
                  Text('Sale un dron disponible', style: muted),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
