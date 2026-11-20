import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api_exception.dart';
import '../../../../core/date_format.dart';
import '../../data/geofence_models.dart';
import '../../data/geofence_providers.dart';

/// RU-36: el historial de una zona legal, lo último primero: qué se hizo,
/// cuándo, qué campos cambiaron y por qué.
class GeofenceHistory extends ConsumerWidget {
  const GeofenceHistory({super.key, required this.geofenceId});

  final String geofenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final body = switch (ref.watch(geofenceChangesProvider(geofenceId))) {
      AsyncData(:final value) when value.isEmpty => [
        Text('Sin cambios desde que llegó con la semilla.', style: muted),
      ],
      AsyncData(:final value) => [
        for (final change in value) _ChangeRow(change: change, muted: muted),
      ],
      AsyncError(:final error) => [
        Text(ApiException.messageOf(error), style: muted),
      ],
      _ => [const LinearProgressIndicator()],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Historial', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        ...body,
      ],
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.change, required this.muted});

  final GeofenceChange change;
  final TextStyle? muted;

  @override
  Widget build(BuildContext context) {
    final fields = change.fields.map(changeFieldLabel).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${change.action.label} · ${formatDateTime(change.createdAt)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (fields.isNotEmpty) Text('Cambió: $fields', style: muted),
          if (change.reason case final reason?) Text('“$reason”', style: muted),
        ],
      ),
    );
  }
}
