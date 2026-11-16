import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/geofence_providers.dart';
import 'legal_zone_sheet.dart';
import 'legal_zone_tile.dart';

/// RF-43: debajo de las geovallas del operador, las zonas legales del
/// escenario (aeropuerto, CAI, batallón, cárcel, plantas y pistas). Solo se
/// leen; si no cargan, la lista de geovallas sigue sirviendo.
class LegalZonesSection extends ConsumerWidget {
  const LegalZonesSection({super.key, this.intro});

  /// Un aviso arriba (p. ej. que el operador aún no tiene geovallas).
  final String? intro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(legalZonesProvider).value ?? const [];
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (intro != null) Text(intro!, style: theme.textTheme.bodyMedium),
        if (zones.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('Zonas legales', style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(
            '${zones.length} zonas de la norma. El motor las rodea; no se editan.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          for (final zone in zones) ...[
            LegalZoneTile(
              zone: zone,
              onTap: () => showLegalZoneSheet(context, zone),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}
