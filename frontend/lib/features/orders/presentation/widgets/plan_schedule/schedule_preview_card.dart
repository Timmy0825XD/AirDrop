import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../../../core/widgets/error_banner.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// Lo que dejaría el calendario: cuántas entregas, las primeras fechas con
/// su franja en hora de Colombia, la última y las que no se agendan por
/// caer a menos de 2 horas.
class SchedulePreviewCard extends StatelessWidget {
  const SchedulePreviewCard({
    super.key,
    required this.preview,
    required this.error,
    required this.loading,
  });

  final PlanPreview? preview;
  final String? error;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = preview;
    return DetailSection(
      title: 'Vista previa',
      icon: Icons.event_note_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loading)
            const LinearProgressIndicator()
          else if (error case final message?)
            ErrorBanner(message: message)
          else if (p == null)
            Text(
              'Completa el calendario para ver las fechas.',
              style: theme.textTheme.bodyMedium,
            )
          else
            _PreviewList(preview: p),
        ],
      ),
    );
  }
}

class _PreviewList extends StatelessWidget {
  const _PreviewList({required this.preview});

  final PlanPreview preview;

  static const _shown = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = preview;
    final count = p.occurrences.length;
    final last = p.lastDate == null
        ? ''
        : ', hasta el ${formatShortDate(p.lastDate!)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          count == 1 ? '1 entrega$last' : '$count entregas$last',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final o in p.occurrences.take(_shown))
          Text(
            '${formatLongDate(o.date)} · '
            '${formatSlot(o.scheduledAt, o.windowEndsAt)}',
            style: theme.textTheme.bodyMedium,
          ),
        if (count > _shown)
          Text('y ${count - _shown} más', style: theme.textTheme.bodySmall),
        if (p.tooSoon.isNotEmpty) ...[
          const SizedBox(height: 10),
          ErrorBanner(
            message:
                'Estas fechas empiezan en menos de 2 horas y no se agendan: '
                '${p.tooSoon.map(formatShortDate).join(', ')}.',
          ),
        ],
      ],
    );
  }
}
