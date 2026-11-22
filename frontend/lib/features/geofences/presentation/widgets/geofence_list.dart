import 'package:flutter/material.dart';

import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/warning_banner.dart';
import '../../../../theme/app_icons.dart';
import '../../data/geofence_models.dart';
import 'geofence_list_values.dart';
import 'geofence_tile.dart';

class GeofenceList extends StatelessWidget {
  const GeofenceList({
    super.key,
    required this.rows,
    required this.filter,
    required this.isAdmin,
    required this.onOpen,
    required this.onDelete,
    required this.onRetry,
    this.problem,
  });
  final List<Geofence>? rows;
  final GeofenceFilter filter;
  final bool isAdmin;
  final ValueChanged<Geofence> onOpen, onDelete;
  final VoidCallback onRetry;
  final String? problem;

  @override
  Widget build(BuildContext context) {
    final shown = rows?.where(filter.keeps).toList();
    if (shown == null || shown.isEmpty) {
      return SliverToBoxAdapter(
        child: _GeofenceListState(
          loading: shown == null && problem == null,
          filter: filter,
          problem: problem,
          onRetry: onRetry,
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        if (problem case final message?)
          SliverToBoxAdapter(
            child: _GeofenceRetry(message: message, onRetry: onRetry),
          ),
        SliverList.separated(
          itemCount: shown.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final g = shown[i];
            return GeofenceTile(
              geofence: g,
              onTap: () => onOpen(g),
              onDelete: g.isOperational && !isAdmin ? () => onDelete(g) : null,
            );
          },
        ),
      ],
    );
  }
}

class _GeofenceListState extends StatelessWidget {
  const _GeofenceListState({
    required this.loading,
    required this.filter,
    required this.onRetry,
    this.problem,
  });
  final bool loading;
  final GeofenceFilter filter;
  final String? problem;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    if (loading) return const SkeletonList();
    if (problem case final message?) {
      return MessageView.error(
        message: message,
        icon: AppIcons.unavailable,
        action: TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      );
    }
    return MessageView(
      icon: AppIcons.geofences,
      title: switch (filter) {
        GeofenceFilter.all => 'Sin zonas registradas',
        GeofenceFilter.operational => 'Sin geovallas operativas',
        GeofenceFilter.legal => 'Sin zonas legales',
      },
      message: filter == GeofenceFilter.operational
          ? 'Crea una geovalla para delimitar una restricción de la operación.'
          : 'Las zonas aparecerán aquí cuando estén registradas.',
    );
  }
}

class _GeofenceRetry extends StatelessWidget {
  const _GeofenceRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WarningBanner(
          message: 'No pudimos actualizar las zonas.\n$message',
          icon: AppIcons.unavailable,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ),
      ],
    ),
  );
}
