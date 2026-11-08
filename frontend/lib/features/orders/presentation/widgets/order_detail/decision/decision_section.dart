import 'package:flutter/material.dart';

import '../../../../../../core/widgets/detail_section.dart';
import '../../../../data/order_models.dart';
import 'decision_summary.dart';
import 'hub_trace_tile.dart';
import 'offer_ladder.dart';

/// "¿Por qué este dron?" (§14): qué decidió el motor en una línea y, al
/// abrirlo, cada central que miró con el veredicto de sus drones y, en una
/// urgencia civil, a quién se le ofreció. Empieza cerrado para no alargar
/// el detalle.
class DecisionSection extends StatefulWidget {
  const DecisionSection({super.key, required this.decision});

  final OrderDecision decision;

  @override
  State<DecisionSection> createState() => _DecisionSectionState();
}

class _DecisionSectionState extends State<DecisionSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final decision = widget.decision;
    final hubs = decision.trace?.hubs ?? const <HubTrace>[];
    final offers = decision.offers ?? const <DispatchOffer>[];
    final hasMore = hubs.isNotEmpty || offers.isNotEmpty;
    return DetailSection(
      title: '¿Por qué este dron?',
      icon: Icons.alt_route_rounded,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.fastOutSlowIn,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              decisionSummary(decision),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_open) ...[
              for (final hub in hubs) HubTraceTile(hub: hub),
              if (offers.isNotEmpty) OfferLadder(offers: offers),
            ],
            if (hasMore)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _open = !_open),
                  icon: Icon(_open ? Icons.expand_less : Icons.expand_more),
                  label: Text(_open ? 'Ocultar' : 'Ver cada central y dron'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
