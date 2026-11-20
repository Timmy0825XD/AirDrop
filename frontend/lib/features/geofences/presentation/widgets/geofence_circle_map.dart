import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_map.dart';

/// RF-21: una geovalla en círculo sobre [AppMap]. Con [onCenter], tocar el
/// mapa mueve el centro; sin él, es la vista previa quieta.
class GeofenceCircleMap extends StatelessWidget {
  const GeofenceCircleMap({
    super.key,
    required this.center,
    required this.radiusM,
    this.onCenter,
    this.sheetHeight = 0,
  });

  final LatLng? center;
  final int radiusM;
  final void Function(LatLng point)? onCenter;
  final double sheetHeight;

  @override
  Widget build(BuildContext context) {
    final danger = Theme.of(context).colorScheme.error;
    final point = center;
    return AppMap(
      fit: point == null ? const [] : _bounds(point),
      interactive: onCenter != null,
      fitPadding: onCenter == null
          ? const EdgeInsets.all(28)
          : EdgeInsets.fromLTRB(40, 120, 84, sheetHeight + 40),
      controlsPadding: EdgeInsets.only(right: 16, bottom: sheetHeight),
      onTap: onCenter,
      layers: [
        if (point != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: point,
                radius: radiusM.toDouble(),
                useRadiusInMeter: true,
                color: danger.withValues(alpha: 0.18),
                borderColor: danger,
                borderStrokeWidth: 3,
              ),
            ],
          ),
      ],
    );
  }

  /// Norte y sur del círculo, para que el mapa lo encuadre entero.
  List<LatLng> _bounds(LatLng point) {
    const distance = Distance();
    return [
      distance.offset(point, radiusM.toDouble(), 0),
      distance.offset(point, radiusM.toDouble(), 180),
    ];
  }
}
