import 'package:flutter/material.dart';

import '../../../../../core/widgets/choice_pill.dart';
import '../../../data/hub_models.dart';
import '../hub_labels.dart';

/// Nodo o ESE (RF-06). Solo un nodo tiene drones: pasar a ESE una central
/// con drones lo rechaza Nest (409) y el mensaje se muestra tal cual.
class HubNetworkChips extends StatelessWidget {
  const HubNetworkChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final HubNetworkRole selected;
  final ValueChanged<HubNetworkRole> onChanged;

  static const _choices = [HubNetworkRole.node, HubNetworkRole.ese];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo de red', style: theme.textTheme.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final role in _choices)
              ChoicePill(
                label: HubLabels.network(role),
                icon: role == HubNetworkRole.node
                    ? Icons.flight_takeoff_rounded
                    : Icons.local_hospital_rounded,
                selected: role == selected,
                onTap: () => onChanged(role),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Solo un nodo tiene drones y despega. Una ESE recibe traslados.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Los cinco tipos de central como chips con su ícono. El elegido se
/// pinta de marca.
class HubTypeChips extends StatelessWidget {
  const HubTypeChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final HubType selected;
  final ValueChanged<HubType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo de central', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in HubType.values)
              ChoicePill(
                label: HubLabels.type(type),
                icon: HubLabels.icon(type),
                selected: type == selected,
                onTap: () => onChanged(type),
              ),
          ],
        ),
      ],
    );
  }
}
