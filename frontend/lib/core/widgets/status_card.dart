import 'package:flutter/material.dart';

import 'glass_card.dart';

/// Tarjeta de una lista de gestión: a la izquierda [leading] (ícono o
/// avatar), en el medio [body] con el estado ([status]) debajo, y a la
/// derecha su acción ([action]). La usan centrales, cuentas, inventario y
/// flota. [footer], si viene, va debajo a todo el ancho (la salud de un
/// dron, por ejemplo), para no apretarlo en la columna del medio.
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [body, const SizedBox(height: 8), status],
          ),
        ),
        const SizedBox(width: 4),
        action,
      ],
    );
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: footer == null
          ? row
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row,
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: footer,
                ),
              ],
            ),
    );
  }
}
