import 'package:flutter/material.dart';

import '../../../../../core/field_limits.dart';
import 'detail_section.dart';

/// Rechazar un pedido en `received`, con un motivo obligatorio que luego
/// ve el solicitante.
class RejectSection extends StatelessWidget {
  const RejectSection({
    super.key,
    required this.reason,
    required this.busy,
    required this.onReject,
  });

  final TextEditingController reason;
  final bool busy;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Rechazar',
      icon: Icons.block_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: reason,
            maxLength: FieldLimits.reason,
            decoration: const InputDecoration(hintText: 'Motivo del rechazo'),
          ),
          OutlinedButton(
            onPressed: busy ? null : onReject,
            child: const Text('Rechazar pedido'),
          ),
        ],
      ),
    );
  }
}
