import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/drone_glyph.dart';
import '../../../../../theme/app_figures.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../fleet/data/fleet_models.dart';
import 'operator_home_values.dart';

class OperatorFleetSummary extends StatelessWidget {
  const OperatorFleetSummary({super.key, required this.data});
  final OperatorHomeValues data;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _ScopeHeading(),
      GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final (index, (status, label, icon)) in [
              (DroneStatus.available, 'Disponibles', AppIcons.drone),
              (DroneStatus.inMission, 'En misión', AppIcons.drone),
              (DroneStatus.maintenance, 'En taller', AppIcons.maintenance),
            ].indexed) ...[
              if (index > 0)
                Container(
                  width: 1,
                  height: 42,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              Expanded(
                child: _FleetCount(
                  label: label,
                  count: data.count(status),
                  icon: icon,
                ),
              ),
            ],
          ],
        ),
      ),
      if (_otherStates(data).isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            _otherStates(data),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
    ],
  );
}

String _otherStates(OperatorHomeValues data) => [
  if ((data.count(DroneStatus.outOfService) ?? 0) > 0)
    '${data.count(DroneStatus.outOfService)} fuera de servicio',
  if ((data.count(DroneStatus.grounded) ?? 0) > 0)
    '${data.count(DroneStatus.grounded)} en espera de rescate',
  if ((data.count(DroneStatus.unknown) ?? 0) > 0)
    '${data.count(DroneStatus.unknown)} con estado por confirmar',
].join(' · ');

class _FleetCount extends StatelessWidget {
  const _FleetCount({
    required this.label,
    required this.count,
    required this.icon,
  });
  final String label;
  final int? count;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: ${count ?? 'sin actualizar'}',
    excludeSemantics: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              if (icon == AppIcons.drone)
                DroneGlyph(
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 20,
                )
              else
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
              Text(
                count == null ? '—' : '$count',
                style: Theme.of(context).textTheme.headlineMedium?.figure,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _ScopeHeading extends StatelessWidget {
  const _ScopeHeading();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        Text('Tu flota', style: Theme.of(context).textTheme.titleLarge),
        Text(
          'Todas tus centrales',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ),
  );
}
