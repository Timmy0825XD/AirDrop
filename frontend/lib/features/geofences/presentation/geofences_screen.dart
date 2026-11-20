import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/presentation/widgets/header_add_button.dart';
import '../../home/presentation/widgets/section_header.dart';
import '../data/geofence_providers.dart';
import 'widgets/geofence_list.dart';

/// RU-19: el catálogo de geovallas para el operador y el admin. El operador
/// crea operativas; el admin, zonas legales (RU-36).
class GeofencesScreen extends ConsumerWidget {
  const GeofencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin =
        ref.watch(authControllerProvider).value?.user?.role == UserRole.admin;
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
              label: isAdmin ? 'Nueva zona legal' : 'Nueva geovalla',
              onPressed: () => context.push('/geofences/new'),
            ),
          ),
          Expanded(child: GeofenceList(isAdmin: isAdmin)),
        ],
      ),
    );
  }
}
