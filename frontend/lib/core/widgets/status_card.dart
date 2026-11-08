import 'package:flutter/material.dart';

import 'glass_card.dart';

/// Tarjeta de una lista de gestión: a la izquierda [leading] (ícono o
/// avatar), en el medio [body] y a la derecha el estado ([status]) con su
/// acción debajo ([action]). La usan centrales y cuentas. [footer], si
/// viene, va debajo a todo el ancho (la salud de un dron, por ejemplo), para
/// no apretarlo en la columna del medio.
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.leading,
    required this.body,
    required this.status,
    required this.action,
    this.footer,
  });

  final Widget leading;
  final Widget body;
  final Widget status;
  final Widget action;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final row = Row(
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
    );
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: footer == null
          ? row
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [row, const SizedBox(height: 12), footer!],
            ),
    );
  }
}
