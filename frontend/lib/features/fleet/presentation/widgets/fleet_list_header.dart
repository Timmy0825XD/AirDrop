import 'package:flutter/material.dart';
import '../../../../theme/app_icons.dart';
import '../../../../core/widgets/choice_pill.dart';
import 'fleet_hub_selector.dart';
import 'fleet_list_values.dart';

class FleetListHeader extends StatelessWidget {
  const FleetListHeader({
    super.key,
    required this.data,
    required this.search,
    required this.onQuery,
    required this.onFilter,
    required this.onHub,
  });
  final FleetListValues data;
  final TextEditingController search;
  final ValueChanged<String> onQuery, onHub;
  final ValueChanged<FleetFilter> onFilter;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FleetHubSelector(
        hubs: data.hubs.value!,
        selectedId: data.hub?.id,
        onChanged: onHub,
      ),
      const SizedBox(height: 14),
      TextField(
        controller: search,
        onChanged: onQuery,
        decoration: InputDecoration(
          hintText: 'Buscar dron',
          prefixIcon: const Icon(AppIcons.search),
          suffixIcon: search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpiar búsqueda',
                  icon: const Icon(AppIcons.close),
                  onPressed: () {
                    search.clear();
                    onQuery('');
                  },
                ),
        ),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in FleetFilter.values)
            ChoicePill(
              label: value.label,
              selected: value == data.filter,
              onTap: () => onFilter(value),
            ),
        ],
      ),
      const SizedBox(height: 18),
    ],
  );
}
