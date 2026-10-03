import 'package:flutter/material.dart';

import '../../../hubs/data/hub_models.dart';

/// Selector de la central que se está gestionando. El operador puede tener
/// una o varias centrales y `POST /fleet/drones` necesita saber en cuál va
/// el dron, así que la lista siempre trabaja sobre una elegida.
///
/// Pinta [selectedId]; la pantalla escucha los cambios. Si la central
/// elegida ya no está en la lista, el dropdown muestra vacío y la pantalla
/// vuelve a la primera.
class FleetHubSelector extends StatelessWidget {
  const FleetHubSelector({
    super.key,
    required this.hubs,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Hub> hubs;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final known = hubs.any((hub) => hub.id == selectedId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CENTRAL',
          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: known ? selectedId : null,
          items: [
            for (final hub in hubs)
              DropdownMenuItem(value: hub.id, child: Text(hub.name)),
          ],
          onChanged: (id) {
            if (id != null) onChanged(id);
          },
        ),
      ],
    );
  }
}
