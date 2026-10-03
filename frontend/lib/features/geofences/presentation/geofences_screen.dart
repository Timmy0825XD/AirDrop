import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../data/geofence_models.dart';
import '../data/geofence_providers.dart';
import 'widgets/geofence_delete_confirm.dart';
import 'widgets/geofence_tile.dart';

/// Listado de geovallas del operador. Cada mutación invalida
/// `geofencesProvider`, así la lista se refresca sin reiniciar la app.
class GeofencesScreen extends ConsumerWidget {
  const GeofencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geovallas')),
      body: const _GeofenceList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/geofences/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva geovalla'),
      ),
    );
  }
}

class _GeofenceList extends ConsumerWidget {
  const _GeofenceList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geofences = ref.watch(geofencesProvider);

    return geofences.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _GeofenceError(message: '$error'),
      data: (rows) => rows.isEmpty
          ? const _GeofenceEmpty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => GeofenceTile(
                geofence: rows[index],
                onTap: () => context.go('/geofences/${rows[index].id}'),
                onDelete: () => _deleteGeofence(context, ref, rows[index]),
              ),
            ),
    );
  }
}

class _GeofenceEmpty extends StatelessWidget {
  const _GeofenceEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aún no hay geovallas registradas.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _GeofenceError extends StatelessWidget {
  const _GeofenceError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

/// Confirma y elimina la geovalla. Los errores de Nest (404 de la
/// geovalla borrada en otra sesión) viajan tal cual a la UI.
Future<void> _deleteGeofence(
  BuildContext context,
  WidgetRef ref,
  Geofence geofence,
) async {
  if (!await confirmGeofenceDelete(context, geofence: geofence)) return;
  if (!context.mounted) return;

  try {
    await ref.read(deleteGeofenceProvider.notifier).delete(geofence.id);
    if (context.mounted) {
      showAppSnack(context, 'Geovalla eliminada.');
    }
  } on ApiException catch (error) {
    if (context.mounted) showAppSnack(context, error.message);
  }
}
