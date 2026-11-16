import 'package:flutter/material.dart';

import '../../../../core/widgets/press_scale.dart';
import '../../../../core/widgets/status_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/widgets/tone_tile.dart';
import '../../data/legal_zone_models.dart';

/// Una zona legal en la lista del operador; tocarla abre su detalle.
class LegalZoneTile extends StatelessWidget {
  const LegalZoneTile({super.key, required this.zone, required this.onTap});

  final LegalZone zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: StatusCard(
          leading: ToneTile.icon(
            icon: zone.kind == LegalZoneKind.aerodrome
                ? Icons.flight_takeoff_rounded
                : Icons.shield_outlined,
            tone: theme.colorScheme.error,
            alpha: 0.10,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                zone.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(zone.kind.label, style: theme.textTheme.bodySmall),
            ],
          ),
          status: const StatusPill(
            label: 'Norma · no se edita',
            tone: PillTone.neutral,
          ),
          action: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
