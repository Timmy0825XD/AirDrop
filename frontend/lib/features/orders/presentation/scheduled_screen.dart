import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';
import '../data/order_models.dart';
import '../data/order_providers.dart';
import 'widgets/order_tray.dart';
import 'widgets/scheduled/scheduled_tile.dart';
import 'widgets/scheduled/scheduled_values.dart';

export 'widgets/scheduled/scheduled_tile.dart' show ScheduledTile;

/// La fecha y los permisos se siguen verificando al revisar el pedido.
class ScheduledScreen extends ConsumerWidget {
  const ScheduledScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      OrderTray<ScheduledEntry>(
        title: 'Programados',
        idleSubtitle: 'Entregas por preparar.',
        countLabel: (n) =>
            n == 1 ? '1 entrega programada' : '$n entregas programadas',
        rows: ref.watch(scheduledProvider),
        onRefresh: () => ref.invalidate(scheduledProvider),
        emptyIcon: AppIcons.calendar,
        emptyTitle: 'Sin entregas programadas',
        emptyText: 'Las próximas entregas de tus planes aparecerán aquí.',
        keyOf: (entry) => entry.order.id,
        groupOf: (entry) => scheduledGroup(entry.order),
        itemBuilder: (context, entry) => ScheduledTile(
          entry: entry,
          onTap: () => context.push('/orders/${entry.order.id}'),
        ),
      );
}
