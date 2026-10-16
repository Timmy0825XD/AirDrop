import 'package:flutter/material.dart';

/// Tarjeta de una lista de gestión: a la izquierda [leading] (ícono o
/// avatar), en el medio [body] y a la derecha el estado ([status]) con su
/// acción debajo ([action]). La usan centrales y cuentas.
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.leading,
    required this.body,
    required this.status,
    required this.action,
  });

  final Widget leading;
  final Widget body;
  final Widget status;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(child: body),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [status, const SizedBox(height: 8), action],
          ),
        ],
      ),
    );
  }
}
