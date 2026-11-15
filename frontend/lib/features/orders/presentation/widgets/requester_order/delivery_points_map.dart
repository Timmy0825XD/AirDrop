import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/widgets/app_map.dart';
import '../../../../../core/widgets/map_markers.dart';
import '../../../data/order_models.dart';

/// Los puntos de entrega en un mapa quieto (no pelea con el scroll del
/// formulario): el elegido va con el acento y cada pin se puede tocar para
/// elegirlo. Con [you], también dónde está el teléfono.
class DeliveryPointsMap extends StatelessWidget {
  const DeliveryPointsMap({
    super.key,
    required this.points,
    required this.onPick,
    this.chosen,
    this.you,
  });

  final List<DeliveryPoint> points;
  final DeliveryPoint? chosen;
  final LatLng? you;
  final ValueChanged<DeliveryPoint> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final spots = [for (final point in points) point.location, ?you];
    return Container(
      height: 168,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline),
      ),
      child: AppMap(
        // Se vuelve a encuadrar cuando llega el GPS o cambian los puntos.
        key: ValueKey('${points.length}-$you'),
        interactive: false,
        zoom: 11,
        center: spots.isEmpty ? AppMap.valledupar : spots.first,
        fit: spots,
        fitPadding: const EdgeInsets.all(36),
        layers: [
          MarkerLayer(
            markers: [
              if (you case final here?) _youMarker(here),
              for (final point in points) _pointMarker(point),
            ],
          ),
        ],
      ),
    );
  }

  Marker _pointMarker(DeliveryPoint point) => Marker(
    point: point.location,
    width: PlacePin.size,
    height: PlacePin.size,
    alignment: Alignment.topCenter,
    child: GestureDetector(
      onTap: () => onPick(point),
      child: PlacePin(
        icon: Icons.place_rounded,
        label: point.name,
        highlight: point.id == chosen?.id,
      ),
    ),
  );

  Marker _youMarker(LatLng here) => Marker(
    point: here,
    width: PlacePin.size,
    height: PlacePin.size,
    alignment: Alignment.topCenter,
    child: const PlacePin(
      icon: Icons.person_pin_circle_rounded,
      label: 'Tu ubicación',
    ),
  );
}
