import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../core/widgets/error_banner.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../../theme/app_icons.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../emergency/emergency_layout.dart';

class PeriodicPreview extends StatelessWidget {
  const PeriodicPreview({
    super.key,
    required this.preview,
    required this.error,
    required this.loading,
    required this.onRetry,
  });
  final PlanPreview? preview;
  final String? error;
  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmergencySurface(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Así quedan tus entregas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (loading) ...[
            const Skeleton(height: 18),
            const SizedBox(height: 8),
            const Skeleton(height: 18, width: 180),
          ] else if (error != null) ...[
            ErrorBanner(message: error!),
            TextButton(
              onPressed: onRetry,
              child: const Text('Revisar fechas otra vez'),
            ),
          ] else if (preview == null)
            const Text('Elige los días para ver las fechas exactas de entrega.')
          else
            _PreviewSummary(preview: preview!),
        ],
      ),
    ),
  );
}

class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({required this.preview});
  final PlanPreview preview;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${preview.occurrences.length} ${preview.occurrences.length == 1 ? 'entrega programada' : 'entregas programadas'}',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      for (final occurrence in preview.occurrences.take(2))
        _OccurrenceLine(occurrence: occurrence),
      if (preview.occurrences.length > 2)
        TextButton(
          onPressed: () => showAppSheet<void>(
            context,
            builder: (_) => _AllDates(preview: preview),
          ),
          child: const Text('Ver todas las fechas'),
        ),
      if (preview.tooSoon.isNotEmpty) ...[
        const SizedBox(height: 12),
        ErrorBanner(
          message:
              'No se agendan estas fechas porque empiezan en menos de 2 horas: ${preview.tooSoon.map(formatDay).join(', ')}.',
        ),
      ],
    ],
  );
}

class _OccurrenceLine extends StatelessWidget {
  const _OccurrenceLine({required this.occurrence});
  final PreviewOccurrence occurrence;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          AppIcons.calendar,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                capitalized(formatDay(occurrence.date, relative: false)),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                formatSlot(occurrence.scheduledAt, occurrence.windowEndsAt),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AllDates extends StatelessWidget {
  const _AllDates({required this.preview});
  final PlanPreview preview;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: 0.76,
    child: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            'Tus fechas de entrega',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          for (final occurrence in preview.occurrences)
            _OccurrenceLine(occurrence: occurrence),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Listo'),
          ),
        ],
      ),
    ),
  );
}
