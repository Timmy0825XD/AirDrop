import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_section_heading.dart';
import '../../data/inventory_models.dart';
import 'inventory_tile.dart';

class InventoryResults extends StatelessWidget {
  const InventoryResults({
    super.key,
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });
  final List<InventoryItem> rows;
  final ValueChanged<InventoryItem> onEdit, onDelete;

  @override
  Widget build(BuildContext context) => SliverList.separated(
    itemCount: rows.length + 1,
    separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 0 : 12),
    itemBuilder: (_, i) {
      if (i == 0) {
        return HomeSectionHeading(
          title: rows.length == 1
              ? '1 lote en inventario'
              : '${rows.length} lotes en inventario',
        );
      }
      final item = rows[i - 1];
      return InventoryTile(
        key: ValueKey(item.id),
        item: item,
        onTap: () => onEdit(item),
        onDelete: () => onDelete(item),
      );
    },
  );
}
