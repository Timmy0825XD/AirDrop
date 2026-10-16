import 'package:flutter/material.dart';

import '../../../../core/widgets/press_scale.dart';

/// Tarjeta de una bandeja de pedidos o planes: ícono teñido, título, una
/// línea de color, una línea gris y, a la derecha, una pastilla opcional y
/// la flecha. Toda la tarjeta abre el detalle y se hunde al tocarla.
class OrderRowCard extends StatelessWidget {
  const OrderRowCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.accent,
    required this.detail,
    required this.onTap,
    this.pill,
  });

  final IconData icon;
  final Color tone;
  final String title;

  /// La línea en color (cantidad, destino, frecuencia).
  final String accent;

  /// La línea gris (stock, fecha).
  final String detail;
  final VoidCallback onTap;
  final Widget? pill;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PressScale(
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _IconBox(icon: icon, tone: tone),
                const SizedBox(width: 12),
                Expanded(child: _Lines(card: this)),
                if (pill != null) ...[const SizedBox(width: 8), pill!],
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.tone});

  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: tone, size: 22),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.card});

  final OrderRowCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          card.accent,
          style: theme.textTheme.bodySmall?.copyWith(
            color: card.tone,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          card.detail,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
