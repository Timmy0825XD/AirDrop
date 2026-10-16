import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';
import '../order_kind_chip.dart';
import '../order_status_chip.dart';

/// Lo que todo el que ve el pedido necesita saber: en qué estado va, qué
/// es, a dónde va y por qué (si fue rechazado o reasignado). El nombre del
/// insumo va en el encabezado de la pantalla.
class OrderSummary extends StatelessWidget {
  const OrderSummary({
    super.key,
    required this.order,
    required this.showPrescriptionFlag,
  });

  final Order order;

  /// El solicitante ve "Lleva fórmula"; el despachador la revisa aparte.
  final bool showPrescriptionFlag;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Datos del pedido',
      icon: Icons.medication_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OrderStatusChip(status: order.status),
              OrderKindChip(missionType: order.missionType),
            ],
          ),
          const SizedBox(height: 14),
          _SummaryLines(order: order, prescription: showPrescriptionFlag),
        ],
      ),
    );
  }
}

class _SummaryLines extends StatelessWidget {
  const _SummaryLines({required this.order, required this.prescription});

  final Order order;
  final bool prescription;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailLine(
          label: 'Venta',
          value: '${order.saleType.label} · ${order.quantity} und.',
        ),
        DetailLine(label: 'Prioridad', value: order.priority.label),
        DetailLine(label: 'Destino', value: destinationLabel(order)),
        DetailLine(label: 'Dirección', value: order.address),
        if (order.description != null)
          DetailLine(label: 'Descripción', value: order.description!),
        if (order.scheduledFor != null)
          DetailLine(label: 'Programada para', value: order.scheduledFor!),
        DetailLine(label: 'Creado', value: formatBogota(order.createdAt)),
        if (order.requiresColdChain)
          const DetailLine(label: 'Cadena de frío', value: 'Sí'),
        if (prescription && order.hasPrescription)
          const DetailLine(label: 'Fórmula', value: 'Lleva fórmula'),
        if (order.statusReason != null)
          DetailLine(label: 'Motivo', value: order.statusReason!),
      ],
    );
  }
}
