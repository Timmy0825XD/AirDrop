import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../../../core/widgets/press_scale.dart';
import '../../../data/order_models.dart';
import '../order_status_chip.dart';
import '../plan_tile.dart';

/// Los datos del plan: estado, frecuencia, cantidad, ventana y destino.
class PlanSummary extends StatelessWidget {
  const PlanSummary({super.key, required this.plan});

  final DeliveryPlan plan;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Plan',
      icon: Icons.event_repeat_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft, child: PlanTile.pillOf(plan)),
          const SizedBox(height: 14),
          DetailLine(label: 'Frecuencia', value: plan.frequency.label),
          DetailLine(
            label: 'Venta',
            value: '${plan.saleType.label} · ${plan.quantity} und.',
          ),
          DetailLine(
            label: 'Ventana',
            value: '${plan.startDate} al ${plan.windowEndsOn}',
          ),
          DetailLine(label: 'Destino', value: plan.destinationKind.label),
          DetailLine(label: 'Dirección', value: plan.address),
        ],
      ),
    );
  }
}

/// Las entregas del plan con su fecha y estado. Tocar una abre su detalle,
/// donde está el dron que la lleva (Nest aquí solo manda su id interno,
/// que antes se mostraba tal cual).
class PlanOccurrences extends StatelessWidget {
  const PlanOccurrences({
    super.key,
    required this.occurrences,
    required this.onOpen,
  });

  final List<PlanOccurrence> occurrences;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Entregas',
      icon: Icons.local_shipping_outlined,
      child: occurrences.isEmpty
          ? Text(
              'Este plan todavía no tiene entregas.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Column(
              children: [
                for (final o in occurrences)
                  _OccurrenceRow(occurrence: o, onTap: () => onOpen(o.id)),
              ],
            ),
    );
  }
}

class _OccurrenceRow extends StatelessWidget {
  const _OccurrenceRow({required this.occurrence, required this.onTap});

  final PlanOccurrence occurrence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = occurrence;
    return PressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(
                o.droneId == null
                    ? Icons.event_outlined
                    : Icons.flight_takeoff_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(o.scheduledFor, style: theme.textTheme.bodyLarge),
              ),
              OrderStatusChip(status: o.status),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
