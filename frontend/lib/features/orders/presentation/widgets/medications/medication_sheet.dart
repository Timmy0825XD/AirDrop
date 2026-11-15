import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_sheet.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../data/order_models.dart';
import 'medication_rules.dart';
import 'medication_tile.dart';

/// Abre el detalle de un medicamento. Devuelve `true` si la persona tocó
/// "Pedir este medicamento".
Future<bool> showMedicationSheet(
  BuildContext context,
  CatalogOffer offer,
) async {
  final order = await showAppSheet<bool>(
    context,
    builder: (_) => MedicationSheet(offer: offer),
  );
  return order ?? false;
}

/// El detalle de un medicamento (CU-49): qué exige, si hay y qué hace
/// falta para pedirlo. El botón empieza la urgencia con ese medicamento ya
/// elegido; lo demás (tamizaje, paciente, fórmula, punto) se pide igual.
/// No muestra cantidad, central, dron ni tiempo de llegada: eso se decide
/// al autorizar.
class MedicationSheet extends StatelessWidget {
  const MedicationSheet({super.key, required this.offer});

  final CatalogOffer offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availability = availabilityOf(offer);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(offer.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(medicationFacts(offer), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          StatusPill(
            label: availability.label,
            tone: availabilityTone(availability),
          ),
          const SizedBox(height: 16),
          Text(
            medicationAdvice(offer),
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
          if (offer.requiresColdChain) ...[
            const SizedBox(height: 8),
            Text(
              'Viaja en un compartimento de frío y la temperatura se vigila '
              'durante el vuelo.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: availability.canOrder
                  ? () => Navigator.of(context).pop(true)
                  : null,
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Pedir este medicamento'),
            ),
          ),
        ],
      ),
    );
  }
}
