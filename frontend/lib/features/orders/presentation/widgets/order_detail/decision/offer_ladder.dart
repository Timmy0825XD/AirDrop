import 'package:flutter/material.dart';

import '../../../../data/order_models.dart';
import '../../../order_format.dart';

/// La escalera de una urgencia civil (RU-10): a qué central se le ofreció,
/// en qué orden y a qué hora, y quién la declinó con su motivo.
class OfferLadder extends StatelessWidget {
  const OfferLadder({super.key, required this.offers});

  final List<DispatchOffer> offers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text('SE OFRECIÓ A', style: theme.textTheme.labelSmall),
        for (final (i, offer) in offers.indexed)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${i + 1}. ${offer.name} · ${offerState(offer)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}

/// "a las 15:02", "declinó a las 15:04: Sin dron disponible" o "todavía
/// no le llega".
String offerState(DispatchOffer offer) {
  final declinedAt = offer.declinedAt;
  if (declinedAt != null) {
    final why = offer.declineReason;
    final at = 'declinó a las ${formatClock(declinedAt)}';
    return why == null || why.isEmpty ? at : '$at: $why';
  }
  final offeredAt = offer.offeredAt;
  return offeredAt == null
      ? 'todavía no le llega'
      : 'desde las ${formatClock(offeredAt)}';
}
