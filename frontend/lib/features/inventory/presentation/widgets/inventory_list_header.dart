import 'package:flutter/material.dart';

import '../../../../core/widgets/sim_clock_badge.dart';
import '../../../../theme/app_icons.dart';
import 'inventory_list_values.dart';

class InventoryListHeader extends StatelessWidget {
  const InventoryListHeader({
    super.key,
    required this.search,
    required this.filter,
    required this.onQuery,
    required this.onFilter,
    required this.onAdd,
  });
  final TextEditingController search;
  final InventoryFilter filter;
  final ValueChanged<String> onQuery;
  final ValueChanged<InventoryFilter> onFilter;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Inventario',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Los insumos de tu central, al día.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SimClockBadge(top: 10),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: onAdd,
        icon: const Icon(AppIcons.add),
        label: const Text('Añadir insumo'),
      ),
      const SizedBox(height: 20),
      _InventorySearch(search: search, onQuery: onQuery),
      const SizedBox(height: 12),
      _InventoryFilters(filter: filter, onFilter: onFilter),
    ],
  );
}

class _InventorySearch extends StatelessWidget {
  const _InventorySearch({required this.search, required this.onQuery});
  final TextEditingController search;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) => TextField(
    controller: search,
    onChanged: onQuery,
    decoration: InputDecoration(
      hintText: 'Buscar medicamento o lote',
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
  );
}

class _InventoryFilters extends StatelessWidget {
  const _InventoryFilters({required this.filter, required this.onFilter});
  final InventoryFilter filter;
  final ValueChanged<InventoryFilter> onFilter;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final value in InventoryFilter.values)
        ChoiceChip(
          label: Text(value.label),
          selected: value == filter,
          showCheckmark: false,
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: value == filter
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
          onSelected: (_) => onFilter(value),
        ),
    ],
  );
}
