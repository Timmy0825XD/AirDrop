import 'package:flutter/material.dart';

import '../../../../theme/app_palette.dart';

/// Lo que va dentro de la barra de vidrio del vuelo: la luz verde con "En
/// vivo" (ámbar "Conectando" si el socket se cayó, o "Sin enlace" si el dron
/// lo perdió), el dron y, para la central de origen, la latencia.
class FlightLiveBar extends StatelessWidget {
  const FlightLiveBar({
    super.key,
    required this.connected,
    required this.identifier,
    this.latencyMs,
    this.linkLost = false,
  });

  final bool connected;
  final String? identifier;
  final double? latencyMs;

  /// Sin enlace (RF-34): lo que se ve es una posición estimada.
  final bool linkLost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final live = connected && !linkLost;
    final mono = theme.textTheme.labelMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: 0.6,
    );
    return Row(
      children: [
        _LiveDot(color: live ? palette.success : palette.warning),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            linkLost
                ? 'Sin enlace · posición estimada'
                : connected
                ? 'En vivo'
                : 'Conectando',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
        ),
        const Spacer(),
        if (identifier != null)
          Text(
            identifier!,
            style: mono?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        if (latencyMs != null) ...[
          const SizedBox(width: 12),
          Text(
            '${latencyMs!.round()} ms',
            style: mono?.copyWith(color: theme.colorScheme.primary),
          ),
        ],
      ],
    );
  }
}

/// La luz de la barra: verde en vivo, ámbar conectando o sin enlace.
class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 8)],
      ),
    );
  }
}

/// El panel vertical del mapa, a la izquierda: altitud y rumbo, como los
/// instrumentos de una cabina.
class FlightHud extends StatelessWidget {
  const FlightHud({super.key, required this.altitudeM, this.headingDeg});

  final double altitudeM;

  /// Rumbo en grados desde el norte; sin ruta, no se muestra.
  final double? headingDeg;

  static const _cardinals = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final heading = headingDeg == null ? null : (headingDeg! + 360) % 360;
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: palette.bar,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.glassBorder),
      ),
      child: Column(
        children: [
          _Gauge(label: 'ALT', value: '${altitudeM.round()}', unit: 'm'),
          if (heading != null) ...[
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              color: palette.glassBorder,
            ),
            _Gauge(
              label: 'RUMBO',
              value: heading.round().toString().padLeft(3, '0'),
              unit: '°${_cardinals[((heading + 22.5) ~/ 45) % 8]}',
            ),
          ],
        ],
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 8.5)),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(unit, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9)),
      ],
    );
  }
}
