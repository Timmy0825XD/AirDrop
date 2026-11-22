import 'package:flutter/material.dart';

import '../../../../../core/widgets/error_banner.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../plan_schedule/schedule_preview_card.dart';

class HubSchedulePreview extends StatelessWidget {
  const HubSchedulePreview({
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
    if (loading) return const Skeleton(height: 18);
    if (error case final message?) return ErrorBanner(message: message);
    final next = preview?.occurrences.firstOrNull;
    if (next == null) {
      return Text(
        'Completa el calendario para ver la próxima entrega.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Próxima entrega: ${formatDay(next.date, relative: false)}.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('Ver las ${preview!.occurrences.length} entregas'),
          initiallyExpanded: preview!.tooSoon.isNotEmpty,
          children: [
            SchedulePreviewCard(preview: preview, error: null, loading: false),
          ],
        ),
      ],
    );
  }
}
