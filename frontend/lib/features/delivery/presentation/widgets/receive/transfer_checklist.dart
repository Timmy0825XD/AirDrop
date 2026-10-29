import 'package:flutter/material.dart';

import '../../../../../core/widgets/yes_no_question.dart';

/// Lo que la central de destino revisa antes de recibir un traslado
/// (centrales.md): si algo no cuadra, el paquete vuelve a origen.
class TransferChecklist extends StatelessWidget {
  const TransferChecklist({
    super.key,
    required this.remissionMatches,
    required this.sealIntact,
    required this.onRemission,
    required this.onSeal,
    this.enabled = true,
  });

  final bool? remissionMatches;
  final bool? sealIntact;
  final ValueChanged<bool> onRemission;
  final ValueChanged<bool> onSeal;
  final bool enabled;

  /// Las dos preguntas tienen respuesta: ya se puede confirmar.
  static bool answered(bool? remission, bool? seal) =>
      remission != null && seal != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('REVISIÓN DEL TRASLADO', style: theme.textTheme.labelSmall),
        const SizedBox(height: 10),
        YesNoQuestion(
          question:
              '¿La remisión coincide con lo recibido (cantidad, lote y '
              'vencimiento)?',
          value: remissionMatches,
          onChanged: onRemission,
          enabled: enabled,
        ),
        const SizedBox(height: 14),
        YesNoQuestion(
          question: '¿El sello llegó intacto?',
          value: sealIntact,
          onChanged: onSeal,
          enabled: enabled,
        ),
      ],
    );
  }
}
