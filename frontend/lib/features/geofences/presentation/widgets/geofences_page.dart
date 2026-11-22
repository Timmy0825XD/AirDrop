import 'package:flutter/material.dart';

import '../../../../core/widgets/choice_pill.dart';
import '../../../../core/widgets/content_page.dart';
import '../../../../theme/app_icons.dart';
import '../../data/geofence_models.dart';
import 'geofence_list.dart';
import 'geofence_list_values.dart';

class GeofencesPage extends StatelessWidget {
  const GeofencesPage({
    super.key,
    required this.rows,
    required this.filter,
    required this.isAdmin,
    required this.onFilter,
    required this.onCreate,
    required this.onOpen,
    required this.onDelete,
    required this.onRetry,
    required this.onRefresh,
    this.problem,
  });
  final List<Geofence>? rows;
  final GeofenceFilter filter;
  final bool isAdmin;
  final ValueChanged<GeofenceFilter> onFilter;
  final ValueChanged<Geofence> onOpen, onDelete;
  final VoidCallback onCreate, onRetry;
  final Future<void> Function() onRefresh;
  final String? problem;
  @override
  Widget build(BuildContext context) => ContentPage(
    title: 'Geovallas',
    subtitle: 'Zonas restringidas',
    onRefresh: onRefresh,
    header: _GeofencesHeader(isAdmin: isAdmin, onCreate: onCreate),
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in GeofenceFilter.values)
                ChoicePill(
                  label: value.label,
                  selected: value == filter,
                  onTap: () => onFilter(value),
                ),
            ],
          ),
        ),
      ),
      GeofenceList(
        rows: rows,
        filter: filter,
        isAdmin: isAdmin,
        onOpen: onOpen,
        onDelete: onDelete,
        onRetry: onRetry,
        problem: problem,
      ),
      if (!isAdmin) const SliverToBoxAdapter(child: _LegalZoneHint()),
    ],
  );
}

class _GeofencesHeader extends StatelessWidget {
  const _GeofencesHeader({required this.isAdmin, required this.onCreate});
  final bool isAdmin;
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: 8,
        runSpacing: 8,
        children: [
          Text(
            'Geovallas',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Tooltip(
            message: isAdmin ? 'Nueva zona legal' : 'Nueva geovalla',
            child: OutlinedButton.icon(
              onPressed: onCreate,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(AppIcons.add, size: 18),
              label: const Text('Crear'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'Zonas restringidas',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _LegalZoneHint extends StatelessWidget {
  const _LegalZoneHint();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          AppIcons.info,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Las zonas legales se consultan aquí.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}
