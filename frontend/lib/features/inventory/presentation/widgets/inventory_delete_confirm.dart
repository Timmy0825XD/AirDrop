import 'package:flutter/material.dart';

import '../../data/inventory_models.dart';

/// Confirma la eliminación de un ítem del inventario.
///
/// Es definitivo (Nest no tiene papelera), así que pide confirmación con
/// el nombre y el lote. Devuelve `true` solo si el despachador confirma.
Future<bool> confirmInventoryDelete(
  BuildContext context, {
  required InventoryItem item,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Eliminar ítem'),
      content: Text(
        '¿Eliminar "${item.name}" (lote ${item.lot}) del inventario? '
        'Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
