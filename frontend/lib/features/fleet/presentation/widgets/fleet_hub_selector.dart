import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/search_picker_sheet.dart';
import '../../../../theme/app_icons.dart';
import '../../../hubs/data/hub_models.dart';

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
    if (hubs.isEmpty) return const SizedBox.shrink();
    final selected =
        hubs.where((h) => h.id == selectedId).firstOrNull ?? hubs.first;
    return Semantics(
      button: true,
      label: 'Cambiar central: ${selected.name}',
      child: GlassCard(
        padding: EdgeInsets.zero,
        radius: 14,
        onTap: () => _chooseHub(context, this),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(selected.isActive ? AppIcons.hub : AppIcons.lock, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selected.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              const RotatedBox(
                quarterTurns: 1,
                child: Icon(AppIcons.next, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _chooseHub(BuildContext context, FleetHubSelector field) async {
  final picked = await showSearchPicker<String>(
    context,
    title: 'Elegir central',
    searchHint: 'Buscar central',
    isSelected: (id) => id == field.selectedId,
    options: [
      for (final hub in field.hubs)
        PickerOption(
          value: hub.id,
          title: hub.name,
          subtitle: hub.isActive ? 'Central activa' : 'Central suspendida',
          icon: hub.isActive ? AppIcons.hub : AppIcons.lock,
        ),
    ],
  );
  if (picked != null && context.mounted) field.onChanged(picked.value);
}
