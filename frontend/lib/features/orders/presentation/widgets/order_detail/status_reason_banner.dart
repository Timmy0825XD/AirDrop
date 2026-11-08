import 'package:flutter/material.dart';

import '../../../../../core/widgets/warning_banner.dart';
import '../../../data/order_models.dart';

/// El aviso de un pedido que sigue su curso pero algo lo hizo volver atrás
/// (RF-34, RF-35, RF-36): el dron tuvo un incidente y el pedido vuelve a
/// despacharse, o la central se quedó sin energía. El texto es el de Nest.
/// Un pedido cerrado (rechazado, devuelto…) dice su motivo en el resumen.
class StatusReasonBanner extends StatelessWidget {
  const StatusReasonBanner({super.key, required this.reason});

  /// `null` si el pedido no trae aviso, ya está cerrado o tiene fallback
  /// (`FallbackCard` ya dice el motivo).
  static String? reasonOf(Order order) =>
      order.inProgress && order.fallback == null ? order.statusReason : null;

  final String reason;

  @override
  Widget build(BuildContext context) => WarningBanner(message: reason);
}
