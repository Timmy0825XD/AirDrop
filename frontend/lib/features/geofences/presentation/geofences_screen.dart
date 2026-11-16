import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/list_padding.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/rise_in.dart';
import '../../home/presentation/widgets/header_add_button.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/geofence_models.dart';
import '../data/geofence_providers.dart';
import 'widgets/geofence_delete_confirm.dart';
import 'widgets/geofence_tile.dart';
import 'widgets/legal_zones_section.dart';
import '../../../core/widgets/skeleton.dart';

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
            trailing: HeaderAddButton(
              label: 'Nueva geovalla',
              onPressed: () => context.push('/geofences/new'),
            ),
          ),
          const Expanded(child: _GeofenceList()),
        ],
      ),
    );
  }
}

class _GeofenceList extends ConsumerWidget {
  const _GeofenceList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(geofencesProvider)) {
      // Arriba las del operador; abajo, las zonas legales (RF-43).
      AsyncValue(hasValue: true, hasError: false, :final value?) =>
        ListView.separated(
          padding: listPadding(context),
          itemCount: value.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => i == value.length
              ? LegalZonesSection(
                  intro: value.isEmpty
                      ? 'Aún no has creado geovallas. Usa "Nueva geovalla".'
                      : null,
                )
              : RiseIn(
                  key: ValueKey(value[i].id),
                  delay: RiseIn.stagger(i),
                  child: GeofenceTile(
                    geofence: value[i],
                    onTap: () => context.push('/geofences/${value[i].id}'),
                    onDelete: () => _deleteGeofence(context, ref, value[i]),
                  ),
                ),
        ),
      AsyncError(:final error) => MessageView.error(
        message: ApiException.messageOf(error),
      ),
      _ => const SkeletonList(),
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
