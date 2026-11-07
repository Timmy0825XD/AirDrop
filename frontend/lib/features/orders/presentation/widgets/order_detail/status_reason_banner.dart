import 'package:flutter/material.dart';

import '../../../../../theme/app_palette.dart';
import '../../../../../theme/app_theme.dart';
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = context.palette.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.report_problem_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
