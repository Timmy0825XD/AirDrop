import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/presentation/widgets/section_form_page.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/geofence_providers.dart';
import 'geofence_form_screen.dart';
import 'legal_zone_form_screen.dart';

/// `/geofences/new` y `/geofences/:id`: elige el formulario por rol y por
/// clase (RU-19, RU-36). El operador edita operativas; el admin, legales.
class GeofenceEditorScreen extends ConsumerWidget {
  const GeofenceEditorScreen({super.key, this.geofenceId});

  final String? geofenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).value?.user?.role;
    final isAdmin = role == UserRole.admin;
    final id = geofenceId;
    if (id == null) {
      return isAdmin ? const LegalZoneFormScreen() : const GeofenceFormScreen();
    }
    final state = ref.watch(geofencesProvider);
    if (state case AsyncError(:final error)) {
      return _message(context, ApiException.messageOf(error));
    }
    final rows = state.value;
    if (rows == null) return const Scaffold(body: SkeletonDetail());
    final geofence = rows.where((row) => row.id == id).firstOrNull;
    if (geofence == null) return _message(context, 'La geovalla no existe.');
    if (geofence.isLegal && isAdmin) {
      return LegalZoneFormScreen(original: geofence);
    }
    if (geofence.isOperational && !isAdmin) {
      return GeofenceFormScreen(original: geofence);
    }
    return _message(
      context,
      geofence.isLegal
          ? 'Las zonas legales las mantiene el administrador.'
          : 'Las geovallas operativas las gestiona el operador de flota.',
    );
  }

  Widget _message(BuildContext context, String text) => SectionStatePage(
    header: SectionHeader(
      title: 'Geovalla',
      subtitle: 'Editar geovalla',
      onBack: () => SectionHeader.backOrHome(context),
    ),
    body: MessageView(icon: Icons.polyline_rounded, message: text),
  );
}
