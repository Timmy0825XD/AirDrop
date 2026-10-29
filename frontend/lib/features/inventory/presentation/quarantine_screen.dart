import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/status_pill.dart';
import '../../orders/presentation/order_format.dart';
import '../../orders/presentation/widgets/order_row_card.dart';
import '../../orders/presentation/widgets/order_tray.dart';
import '../../../theme/app_palette.dart';
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
      idleSubtitle: 'Lotes devueltos que no reingresan',
      countLabel: (n) => n == 1 ? '1 lote en cuarentena' : '$n lotes',
      rows: ref.watch(quarantineProvider),
      onRefresh: () => ref.invalidate(quarantineProvider),
      emptyIcon: Icons.verified_outlined,
      emptyText: 'No hay lotes en cuarentena.',
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
    return OrderRowCard(
      icon: record.reason == QuarantineReason.coldChain
          ? Icons.ac_unit_rounded
          : Icons.inventory_2_outlined,
      tone: context.palette.warning,
      title: record.medicationName,
      accent: '${record.quantity} und. · Lote ${record.lot}',
      detail:
          'Vence ${record.expirationDate} · ${formatBogota(record.createdAt)}',
      pill: StatusPill(label: record.reason.label, tone: PillTone.attention),
      onTap: onTap,
    );
  }
}
