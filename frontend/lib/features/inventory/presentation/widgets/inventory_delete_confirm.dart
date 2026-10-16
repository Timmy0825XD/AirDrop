import 'package:flutter/material.dart';

import '../../../../core/widgets/confirm_sheet.dart';
import '../../data/inventory_models.dart';

/// Confirma la eliminación de un ítem del inventario en la hoja inferior.
///
/// Es definitivo (Nest no tiene papelera), así que la hoja muestra el
/// nombre, el lote y la cantidad. Devuelve `true` solo si se confirma.
Future<bool> confirmInventoryDelete(
  BuildContext context, {
  required InventoryItem item,
}) {
  return showConfirmSheet(
    context,
    title: 'Eliminar ítem',
    message: 'Sale del inventario de tu central. No se puede deshacer.',
    confirmLabel: 'Eliminar',
    icon: Icons.delete_outline_rounded,
    subject: _ItemSummary(item: item),
  );
}

class _ItemSummary extends StatelessWidget {
  const _ItemSummary({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(item.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Lote ${item.lot} · ${item.quantity} und.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
