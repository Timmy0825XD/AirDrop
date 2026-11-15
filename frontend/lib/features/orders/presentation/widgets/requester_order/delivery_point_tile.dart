import 'package:flutter/material.dart';

import '../../../../../core/widgets/press_scale.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// "Badillo · Valledupar · 0,3 km": lo que dice un punto bajo su nombre.
String deliveryPointFacts(DeliveryPoint point, {bool nearest = false}) => [
  if (point.municipality.isNotEmpty) point.municipality,
  if (point.distanceKm case final km?) formatKm(km),
  if (nearest) 'El más cercano',
  if (point.corridorZone != null) 'Corredor pactado',
].join(' · ');

/// Un punto de entrega de la lista: nombre, municipio, distancia y si es
/// el más cercano o tiene corredor pactado. El elegido lleva el borde del
/// acento y el check; no se distingue solo por color.
class DeliveryPointTile extends StatelessWidget {
  const DeliveryPointTile({
    super.key,
    required this.point,
    required this.selected,
    required this.onTap,
    this.nearest = false,
  });

  final DeliveryPoint point;
  final bool selected;
  final bool nearest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final facts = deliveryPointFacts(point, nearest: nearest);
    return Semantics(
      button: true,
      selected: selected,
      label: '${point.name}. $facts',
      excludeSemantics: true,
      child: PressScale(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? colors.primary.withValues(alpha: 0.08) : null,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? colors.primary : colors.outline,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PointText(name: point.name, facts: facts),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El nombre y, debajo, lo que se sabe del punto; a dos líneas.
class _PointText extends StatelessWidget {
  const _PointText({required this.name, required this.facts});

  final String name;
  final String facts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        if (facts.isNotEmpty)
          Text(
            facts,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Cómo se recibe en un punto de entrega.
class PickupNote extends StatelessWidget {
  const PickupNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_rounded, size: 18, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'El dron no llega a las casas: baja en el punto de entrega. Ve '
            'hasta allá con tu código para recibir el medicamento.',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
