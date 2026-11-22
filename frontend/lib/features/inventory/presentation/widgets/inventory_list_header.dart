import 'package:flutter/material.dart';

import '../../../../core/widgets/choice_pill.dart';
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
      _InventoryTitle(onAdd: onAdd),
      const SizedBox(height: 6),
      Text(
        'Insumos de tu central',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SimClockBadge(top: 10),
      const SizedBox(height: 20),
      _InventorySearch(search: search, onQuery: onQuery),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in InventoryFilter.values)
            ChoicePill(
              label: value.label,
              selected: value == filter,
              onTap: () => onFilter(value),
            ),
        ],
      ),
    ],
  );
}

class _InventoryTitle extends StatelessWidget {
  const _InventoryTitle({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children: [
      Text(
        'Inventario',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -.6,
        ),
      ),
      Tooltip(
        message: 'Añadir insumo',
        child: OutlinedButton.icon(
          onPressed: onAdd,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(AppIcons.add, size: 18),
          label: const Text('Añadir'),
        ),
      ),
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
