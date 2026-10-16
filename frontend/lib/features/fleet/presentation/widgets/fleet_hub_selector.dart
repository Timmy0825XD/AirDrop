import 'package:flutter/material.dart';

import '../../../../core/widgets/choice_pill.dart';
import '../../../hubs/data/hub_models.dart';

/// Las centrales del operador en chips que se deslizan de lado. Siempre
/// hay una elegida: `POST /fleet/drones` necesita saber en cuál va el dron.
/// Una central suspendida lleva su candado.
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
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: hubs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final hub = hubs[i];
          return ChoicePill(
            label: hub.name,
            icon: hub.isActive ? null : Icons.lock_outline_rounded,
            selected: hub.id == selectedId,
            onTap: () => onChanged(hub.id),
          );
        },
      ),
    );
  }
}
