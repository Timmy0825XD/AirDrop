import 'package:flutter/material.dart';

import '../../../../core/widgets/confirm_sheet.dart';
import '../../data/geofence_models.dart';

/// Confirma la eliminación de una geovalla en la hoja inferior.
///
/// Es definitiva (Nest no tiene papelera) y cambia por dónde pueden volar
/// los drones, así que la hoja muestra cuál es. Devuelve `true` solo si
/// el operador confirma.
Future<bool> confirmGeofenceDelete(
  BuildContext context, {
  required Geofence geofence,
}) {
  final theme = Theme.of(context);
  return showConfirmSheet(
    context,
    title: 'Eliminar geovalla',
    message: 'Los drones podrán volver a pasar por esta zona.',
    confirmLabel: 'Eliminar',
    icon: Icons.delete_outline_rounded,
    subject: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(geofence.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(geofence.reason, style: theme.textTheme.bodySmall),
        ],
      ),
    ),
  );
}
