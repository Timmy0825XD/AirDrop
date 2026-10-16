import 'package:flutter/material.dart';

/// Tarjeta con título para cada bloque del detalle (datos, dron, acciones).
class DetailSection extends StatelessWidget {
  const DetailSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Una línea "etiqueta: valor" dentro de una sección.
class DetailLine extends StatelessWidget {
  const DetailLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
