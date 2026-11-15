import 'package:flutter/material.dart';

import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../../core/widgets/tone_tile.dart';
import '../../../../inventory/data/inventory_models.dart' show SaleType;
import '../../../data/order_models.dart';
import 'medication_rules.dart';

/// El tono de la pastilla de cada disponibilidad. El texto dice lo mismo
/// que el color: nunca se comunica solo con color.
PillTone availabilityTone(Availability availability) => switch (availability) {
  Availability.available => PillTone.positive,
  Availability.few => PillTone.attention,
  Availability.none || Availability.notHere => PillTone.neutral,
};

/// Lo que exige el medicamento, en una línea: "Bajo fórmula · Viaja en
/// frío". No dice cantidad, lote, central ni tiempos (RF-54).
String medicationFacts(CatalogOffer offer) => [
  offer.saleType.label,
  if (offer.requiresColdChain) 'Viaja en frío',
].join(' · ');

/// Un medicamento de la lista: el ícono (el copo si viaja en frío), el
/// nombre, lo que exige y la disponibilidad en palabras. Toda la tarjeta
/// abre el detalle.
class MedicationTile extends StatelessWidget {
  const MedicationTile({super.key, required this.offer, required this.onTap});

  final CatalogOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availability = availabilityOf(offer);
    return Semantics(
      button: true,
      label: '${offer.name}. ${medicationFacts(offer)}. ${availability.label}.',
      excludeSemantics: true,
      child: GlassCard(
        onTap: onTap,
        child: Row(
          children: [
            ToneTile.icon(
              icon: offer.requiresColdChain
                  ? Icons.ac_unit_rounded
                  : Icons.medication_rounded,
              tone: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    medicationFacts(offer),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  StatusPill(
                    label: availability.label,
                    tone: availabilityTone(availability),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo que hay que saber antes de pedir, según el tipo de venta.
String medicationAdvice(CatalogOffer offer) => switch (offer.saleType) {
  SaleType.specialControl =>
    'Los medicamentos de control especial no viajan por dron. Pídelo en '
        'tu punto de atención.',
  SaleType.prescription =>
    'Necesitas la fórmula médica a nombre del paciente: un PDF o hasta 3 '
        'fotos. El despachador la revisa antes de autorizar.',
  SaleType.overTheCounter =>
    'Es de venta libre: no necesitas fórmula. Un despachador revisa tu '
        'pedido antes de autorizar.',
};
