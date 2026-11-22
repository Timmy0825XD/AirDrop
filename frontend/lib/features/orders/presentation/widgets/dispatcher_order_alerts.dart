import 'package:flutter/material.dart';
import '../../../../core/widgets/warning_banner.dart';
import '../../data/order_models.dart';

class DispatcherOrderAlerts extends StatelessWidget {
  const DispatcherOrderAlerts({super.key, required this.order});
  final Order order;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (order.coldChainAlert)
        const WarningBanner(message: 'Alerta de cadena de frío'),
      if (order.statusReason case final reason?)
        Padding(padding: const EdgeInsets.only(top: 6), child: Text(reason)),
      if (order.receiptRejectedReason case final reason?)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Recepción rechazada: $reason'),
        ),
    ],
  );
}
