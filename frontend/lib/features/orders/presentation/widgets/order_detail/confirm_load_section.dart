import 'package:flutter/material.dart';

import 'detail_section.dart';

/// Confirmar la carga: el despachador de la central de origen avisa que el
/// insumo ya va en el dron. Recién ahí arranca la simulación del vuelo.
class ConfirmLoadSection extends StatelessWidget {
  const ConfirmLoadSection({
    super.key,
    required this.busy,
    required this.onConfirm,
  });

  final bool busy;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Confirmar carga',
      icon: Icons.inventory_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pon el insumo en el dron y confírmalo. El vuelo arranca en '
            'segundos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: busy ? null : onConfirm,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Confirmar carga'),
          ),
        ],
      ),
    );
  }
}
