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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
