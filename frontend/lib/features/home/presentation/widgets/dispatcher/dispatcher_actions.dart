import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/rise_in.dart';
import '../../../../hubs/data/hub_models.dart';
import 'dispatcher_cards.dart';
import 'dispatcher_counts.dart';

/// Los accesos del despachador en tres grupos: lo que hay que atender, su
/// central y lo que le pide a otra central. Sin central activa todo queda
/// con candado menos Mi central y Mis planes. Entran en cascada.
class DispatcherActions extends StatelessWidget {
  const DispatcherActions({super.key, required this.hub, required this.counts});

  final Hub? hub;
  final DispatcherCounts? counts;

  @override
  Widget build(BuildContext context) {
    final active = hub?.isActive ?? false;
    VoidCallback? open(String path, {bool always = false}) =>
        active || (always && hub != null) ? () => context.go(path) : null;
    final cards = [
      ...operationCards(context, open, counts),
      ...hubCards(context, open),
      ...requestCards(context, open),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, card) in cards.indexed)
          RiseIn(
            delay: RiseIn.stagger(i + 2),
            child: Padding(
              padding: EdgeInsets.only(bottom: card is AccessGroup ? 12 : 10),
              child: card,
            ),
          ),
      ],
    );
  }
}
