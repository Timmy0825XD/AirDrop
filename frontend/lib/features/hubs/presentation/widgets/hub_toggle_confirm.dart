import 'package:flutter/material.dart';

import '../../data/hub_models.dart';

/// Confirma la suspensión o la reactivación de una central.
///
/// Es reversible, pero en el momento bloquea inventario y flota de esa
/// central, así que pide confirmación. Devuelve `true` solo si el
/// administrador lo confirma.
Future<bool> confirmHubSuspension(BuildContext context, {required Hub hub}) async {
  final suspend = hub.isActive;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(suspend ? 'Suspender central' : 'Reactivar central'),
      content: Text(
        suspend
            ? '¿Quieres suspender "${hub.name}"? El inventario y la flota de '
                'esa central quedan bloqueados hasta que la reactives.'
            : '¿Quieres reactivar "${hub.name}"?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(suspend ? 'Suspender' : 'Reactivar'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
