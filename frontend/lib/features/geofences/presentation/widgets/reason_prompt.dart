import 'package:flutter/material.dart';

import '../../../../core/field_limits.dart';

/// RU-36: pide el motivo de un cambio a una zona legal. `null` si se
/// cancela; no deja confirmar en blanco.
Future<String?> showReasonPrompt(
  BuildContext context, {
  required String title,
  required String confirmLabel,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (dialog, setState) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: FieldLimits.reason,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            hintText: 'Ej.: La Policía cerró el CAI',
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: controller.text.trim().isEmpty
                ? null
                : () => Navigator.of(dialog).pop(controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  ).whenComplete(controller.dispose);
}
