import 'package:flutter/material.dart';

import '../../data/hub_models.dart';

/// Filtro del listado del administrador. `null` significa "Todas" y así lo
/// espera `GET /hubs?status=`: sin parámetro Nest devuelve todo.
class HubFilterTabs extends StatelessWidget {
  const HubFilterTabs({super.key, required this.selected, required this.onSelect});

  final HubStatus? selected;
  final ValueChanged<HubStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<HubStatus?>(
      segments: const [
        ButtonSegment(value: null, label: Text('Todas')),
        ButtonSegment(value: HubStatus.active, label: Text('Activas')),
        ButtonSegment(value: HubStatus.suspended, label: Text('Suspendidas')),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onSelect(selection.first),
    );
  }
}
