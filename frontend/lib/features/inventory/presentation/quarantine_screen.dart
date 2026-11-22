import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_icons.dart';

import '../../../core/widgets/status_pill.dart';
import '../../../core/date_format.dart';
import '../../orders/presentation/widgets/dispatcher_order_card.dart';
import '../../orders/presentation/widgets/order_fact_row.dart';
import '../../orders/presentation/widgets/order_tray.dart';
import 'widgets/quarantine_empty_card.dart';
import '../data/inventory_models.dart';
import '../data/inventory_providers.dart';

/// La cuarentena de la central (`/inventory/quarantine`, HU-34): los lotes
/// devueltos que no volvieron al stock por frío o por el empaque. Tocar una
/// fila abre el pedido.
class QuarantineScreen extends ConsumerWidget {
  const QuarantineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrderTray<QuarantineRecord>(
      title: 'Cuarentena',
      idleSubtitle: 'Insumos que no regresan al stock.',
      countLabel: (n) => n == 1 ? '1 lote en cuarentena' : '$n lotes',
      rows: ref.watch(quarantineProvider),
      onRefresh: () => ref.invalidate(quarantineProvider),
      emptyIcon: AppIcons.privacy,
      emptyTitle: 'Sin lotes en cuarentena',
      emptyText:
          'Los insumos devueltos que no puedan volver al inventario aparecerán aquí.',
      emptyBody: QuarantineEmptyCard(
        onRefresh: () => ref.invalidate(quarantineProvider),
      ),
      keyOf: (row) => row.id,
      itemBuilder: (context, row) => QuarantineTile(
        record: row,
        onTap: () => context.push('/orders/${row.orderId}'),
      ),
    );
  }
}

/// Un lote en cuarentena: qué, cuánto, lote y vencimiento, y el motivo.
class QuarantineTile extends StatelessWidget {
  const QuarantineTile({super.key, required this.record, required this.onTap});

  final QuarantineRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DispatcherOrderCard(
      title: record.medicationName,
      subtitle: '${record.quantity} unidades · Lote ${record.lot}',
      status: StatusPill(
        label: record.reason.label,
        tone: PillTone.attention,
        wrapLabel: true,
      ),
      facts: [
        OrderFactRow(
          icon: AppIcons.calendar,
          label: 'Vence ${formatDay(record.expirationDate)}',
        ),
        OrderFactRow(
          icon: AppIcons.incoming,
          label: 'Ingresó ${formatDateTime(record.createdAt)}',
        ),
      ],
      onTap: onTap,
      dividedFooter: true,
      footer: OrderDetailAction(onTap: onTap, label: 'Ver pedido'),
    );
  }
}
