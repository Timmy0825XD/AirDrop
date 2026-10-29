import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/hub_models.dart';

/// Lo que el administrador hace con una central al tocarla: editarla o ver
/// su flota. Suspender y reactivar siguen en el botón de la tarjeta.
Future<void> showHubActionsSheet(BuildContext context, Hub hub) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(hub.name, style: Theme.of(sheet).textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar central'),
            subtitle: const Text(
              'Nombre, tipo, dirección, ubicación y contacto',
            ),
            onTap: () {
              Navigator.of(sheet).pop();
              context.go('/hubs/${hub.id}/edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.flight_rounded),
            title: const Text('Ver flota'),
            subtitle: const Text('Sus drones, solo lectura'),
            onTap: () {
              Navigator.of(sheet).pop();
              context.push('/hubs/${hub.id}/fleet');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
