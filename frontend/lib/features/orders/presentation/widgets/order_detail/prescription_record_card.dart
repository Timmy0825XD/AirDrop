import 'package:flutter/material.dart';

import '../../../../../core/widgets/detail_section.dart';

/// La fórmula de un pedido que la central ya autorizó (RF-27, CU-13): se
/// puede volver a abrir, sin cambiarla, para una auditoría o un reclamo.
class PrescriptionRecordCard extends StatelessWidget {
  const PrescriptionRecordCard({
    super.key,
    required this.busy,
    required this.onView,
  });

  final bool busy;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DetailSection(
      title: 'Fórmula médica',
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu central autorizó este pedido con esta fórmula. Queda aquí para '
            'una auditoría o un reclamo; no se puede cambiar.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : onView,
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Ver fórmula'),
          ),
        ],
      ),
    );
  }
}
