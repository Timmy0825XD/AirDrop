import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/widgets/app_map.dart';
import '../../../../../core/widgets/map_markers.dart';
import '../../../../hubs/data/hub_models.dart';
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// El mapa del traslado si ya se eligió la central de origen y las dos
/// centrales tienen coordenadas; si no, nada (el formulario sigue igual).
Widget? transferMapOf({
  required List<OriginHub>? origins,
  required String? originHubId,
  required Hub? mine,
}) {
  final origin = origins?.where((h) => h.id == originHubId).firstOrNull;
  final lat = origin?.latitude;
  final lng = origin?.longitude;
  if (origin == null || lat == null || lng == null || mine == null) {
    return null;
  }
  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: TransferMap(
      from: LatLng(lat, lng),
      fromName: origin.name,
      to: LatLng(mine.latitude, mine.longitude),
    ),
  );
}

/// El traslado en un mapa quieto, dentro del formulario de pedir a otra
/// central: la central que lo manda (cuadro con la cruz) y la tuya (el
/// blanco), unidas por una línea punteada, y debajo la distancia en línea
/// recta. La ruta de verdad la calcula Nest al autorizar (esquiva
/// geovallas), así que la línea solo orienta.
class TransferMap extends StatelessWidget {
  const TransferMap({
    super.key,
    required this.from,
    required this.fromName,
    required this.to,
  });

  final LatLng from;
  final String fromName;
  final LatLng to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final km = const Distance().as(LengthUnit.Meter, from, to) / 1000;
    return Semantics(
      label: 'Mapa del traslado desde $fromName hasta tu central',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 170,
              child: AppMap(
                interactive: false,
                fit: [from, to],
                layers: [_TransferLayer(from: from, to: to)],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'De $fromName a tu central · ${formatKm(km)} en línea recta',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// La línea punteada y las dos centrales.
class _TransferLayer extends StatelessWidget {
  const _TransferLayer({required this.from, required this.to});

  final LatLng from;
  final LatLng to;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Stack(
      children: [
        PolylineLayer(
          polylines: [
            Polyline(
              points: [from, to],
              strokeWidth: 3,
              color: accent.withValues(alpha: 0.6),
              pattern: StrokePattern.dashed(segments: const [8, 9]),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: from,
              width: HubMarker.size,
              height: HubMarker.size,
              child: const HubMarker(),
            ),
            Marker(
              point: to,
              width: TargetMarker.size,
              height: TargetMarker.size,
              child: const TargetMarker(),
            ),
          ],
        ),
      ],
    );
  }
}
