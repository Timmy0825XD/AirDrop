import 'package:flutter/material.dart';

/// El espacio de las métricas, con borde punteado y "Próximamente": Nest
/// todavía no tiene el módulo (`context/producto/pendientes-backend.md`,
/// punto 4). No se puede tocar.
class AdminMetricsCard extends StatelessWidget {
  const AdminMetricsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = colors.onSurfaceVariant;
    return CustomPaint(
      painter: _DashedBorderPainter(color: colors.outline, radius: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.bar_chart_rounded, color: muted, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Métricas',
                    style: theme.textTheme.titleMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Llegan cuando el backend tenga el módulo.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              'PRÓXIMAMENTE',
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Borde de trazos alrededor de un rectángulo redondeado.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
