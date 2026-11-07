import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../core/widgets/slide_to_launch.dart';
import '../../../data/order_models.dart';
import 'load_check_values.dart';

/// Antes de confirmar la carga: lo que el despachador revisa con el paquete
/// en la mano y "Desliza para despegar". Devuelve `true` solo si deslizó;
/// cerrar la hoja no lanza nada. Confirmar la carga arranca el vuelo y no
/// tiene vuelta atrás, así que no basta un toque (el mismo gesto que pedir
/// una urgencia).
Future<bool> showLoadCheckSheet(BuildContext context, Order order) async {
  final launch = await showAppSheet<bool>(
    context,
    builder: (sheet) => LoadCheckSheet(
      order: order,
      onLaunch: () async => Navigator.pop(sheet, true),
    ),
  );
  return launch ?? false;
}

class LoadCheckSheet extends StatelessWidget {
  const LoadCheckSheet({
    super.key,
    required this.order,
    required this.onLaunch,
  });

  final Order order;
  final Future<void> Function() onLaunch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Revisa la carga', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Con el paquete en la mano. Al deslizar, el dron despega y ya '
              'no se puede detener.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            for (final item in loadChecklist(order)) _CheckRow(item: item),
            const SizedBox(height: 10),
            SlideToLaunch(
              label: 'Desliza para despegar',
              loadingLabel: 'Despegando',
              onLaunch: onLaunch,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.item});

  final LoadCheckItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(item.icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(item.text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
