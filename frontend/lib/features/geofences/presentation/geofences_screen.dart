import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/geofence_models.dart';
import '../data/geofence_providers.dart';
import 'widgets/geofence_delete_confirm.dart';
import 'widgets/geofence_tile.dart';

/// Las geovallas: zonas por donde el motor de rutas no deja pasar al dron.
/// Tocar una abre su edición; "Nueva geovalla" abre el formulario encima.
class GeofencesScreen extends ConsumerWidget {
  const GeofencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(geofencesProvider).value?.length;
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Geovallas',
            subtitle: count == null
                ? 'Zonas restringidas'
                : count == 1
                ? '1 zona restringida'
                : '$count zonas restringidas',
            onBack: () => context.go('/home'),
          ),
          const Expanded(child: _GeofenceList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/geofences/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva geovalla'),
      ),
    );
  }
}

class _GeofenceList extends ConsumerWidget {
  const _GeofenceList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(geofencesProvider)) {
      AsyncValue(hasValue: true, hasError: false, :final value?) when value.isEmpty => const MessageView(
        icon: Icons.polyline_outlined,
        message: 'Aún no hay geovallas registradas.',
      ),
      AsyncValue(hasValue: true, hasError: false, :final value?) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
        itemCount: value.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => RiseIn(
          key: ValueKey(value[i].id),
          delay: RiseIn.stagger(i),
          child: GeofenceTile(
            geofence: value[i],
            onTap: () => context.push('/geofences/${value[i].id}'),
            onDelete: () => _deleteGeofence(context, ref, value[i]),
          ),
        ),
      ),
      AsyncError(:final error) => MessageView(
        icon: Icons.cloud_off_rounded,
        message: ApiException.messageOf(error),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
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
    if (context.mounted) showAppSnack(context, 'Geovalla eliminada.');
  } on ApiException catch (error) {
    if (context.mounted) showErrorSnack(context, error.message);
  }
}
