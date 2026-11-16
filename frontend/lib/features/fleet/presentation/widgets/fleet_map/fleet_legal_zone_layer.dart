import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/app_map.dart';
import '../../../../geofences/data/geofence_providers.dart';

/// RF-43: las zonas legales (aeropuerto, CAI, batallón…) en el mapa en vivo,
/// más suaves que las geovallas del operador: se ven, pero no se tocan.
class FleetLegalZoneLayer extends ConsumerWidget {
  const FleetLegalZoneLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(legalZonesProvider).value ?? const [];
    final danger = Theme.of(context).colorScheme.error;
    return PolygonLayer(
      polygons: [
        for (final zone in zones)
          if (zone.polygon.ring.length >= 3)
            Polygon(
              points: zone.polygon.ring.map(latLngFromGeoJson).toList(),
              color: danger.withValues(alpha: 0.08),
              borderColor: danger.withValues(alpha: 0.55),
              borderStrokeWidth: 1.2,
            ),
      ],
    );
  }
}
