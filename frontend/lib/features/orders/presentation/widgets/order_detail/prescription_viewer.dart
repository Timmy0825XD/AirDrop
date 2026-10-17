import 'package:flutter/material.dart';

import '../../../data/order_models.dart';
import '../prescription_checklist.dart';

/// Muestra la imagen de la fórmula a pantalla completa con la lista de lo
/// que hay que revisar. La imagen vive solo en memoria.
Future<void> showPrescription(BuildContext context, PrescriptionFile file) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fórmula'),
          leading: IconButton(
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InteractiveViewer(
              child: Image.memory(
                file.bytes,
                // Una imagen dañada no muestra el error técnico del motor.
                errorBuilder: (context, _, _) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No se pudo mostrar la imagen de la fórmula. Si no se '
                    'puede verificar, rechaza el pedido con ese motivo.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const PrescriptionChecklist(),
          ],
        ),
      ),
    ),
  );
}
