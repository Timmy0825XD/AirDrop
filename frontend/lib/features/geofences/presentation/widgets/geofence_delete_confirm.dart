import 'package:flutter/material.dart';

import '../../data/geofence_models.dart';

/// Confirma la eliminación de una geovalla.
///
/// Es definitiva (Nest no tiene papelera), así que pide confirmación con
/// el nombre. Devuelve `true` solo si el operador confirma.
Future<bool> confirmGeofenceDelete(
  BuildContext context, {
  required Geofence geofence,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Eliminar geovalla'),
      content: Text(
        '¿Eliminar "${geofence.name}"? Esta acción no se puede deshacer.',
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
