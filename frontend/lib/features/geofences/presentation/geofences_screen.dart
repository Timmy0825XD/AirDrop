import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_exception.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/geofence_models.dart';
import '../data/geofence_providers.dart';
import 'widgets/geofence_delete_confirm.dart';
import 'widgets/geofence_detail_sheet.dart';
import 'widgets/geofence_list_values.dart';
import 'widgets/geofences_page.dart';

/// El operador gestiona operativas; el administrador mantiene las legales.
class GeofencesScreen extends ConsumerStatefulWidget {
  const GeofencesScreen({super.key});
  @override
  ConsumerState<GeofencesScreen> createState() => _GeofencesScreenState();
}

class _GeofencesScreenState extends ConsumerState<GeofencesScreen> {
  GeofenceFilter _filter = GeofenceFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(geofencesProvider);
    final isAdmin =
        ref.watch(authControllerProvider).value?.user?.role == UserRole.admin;
    void open(Geofence g) {
      if (g.isOperational && !isAdmin) {
        context.push('/geofences/${g.id}');
      } else {
        showGeofenceDetailSheet(context, g, isAdmin: isAdmin);
      }
    }

    return GeofencesPage(
      rows: state.value,
      filter: _filter,
      isAdmin: isAdmin,
      problem: state.hasError ? ApiException.messageOf(state.error!) : null,
      onFilter: (value) => setState(() => _filter = value),
      onCreate: () => context.push('/geofences/new'),
      onOpen: open,
      onDelete: (g) => deleteGeofence(context, ref, g),
      onRetry: () => ref.invalidate(geofencesProvider),
      onRefresh: () async {
        try {
          final refreshed = ref.refresh(geofencesProvider.future);
          await refreshed;
        } catch (_) {
          /* El estado del provider muestra el error y el reintento. */
        }
      },
    );
  }
}
