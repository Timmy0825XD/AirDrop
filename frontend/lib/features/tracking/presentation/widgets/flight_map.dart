import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_map.dart';
import '../../../../core/widgets/map_markers.dart';
import '../../../../theme/app_palette.dart';

/// El mapa del vuelo, a pantalla completa: la ruta del pedido (lo
/// recorrido sólido, lo que falta punteado), la central de origen, el
/// destino y el dron que la cámara acompaña. En el regreso ([returnLeg])
/// pinta la ruta de vuelta (`assignment.returnRoute`), que va del destino
/// a la central.
///
/// La ruta llega como pares `[longitud, latitud]` (GeoJSON) y aquí se
/// voltea a `LatLng(latitud, longitud)`, que es lo que pide el mapa.
class FlightMap extends StatelessWidget {
  const FlightMap({
    super.key,
    required this.route,
    this.drone,
    this.sheetHeight = 0,
    this.returnLeg = false,
  });

  /// Puntos del corredor, `[longitud, latitud]`.
  final List<List<double>> route;

  /// Posición actual del dron; `null` mientras no hay vuelo.
  final LatLng? drone;

  /// Lo que tapa la hoja de abajo: la cámara y los botones lo dejan libre.
  final double sheetHeight;

  /// [route] es la ruta de regreso: empieza en el destino.
  final bool returnLeg;

  @override
  Widget build(BuildContext context) {
    final points = route.map(latLngFromGeoJson).toList();
    return AppMap(
      // El encuadre solo aplica al crear el mapa: si la ruta llega después
      // (el pedido aún cargaba), se vuelve a montar para encuadrarla.
      key: ValueKey(points.length >= 2),
      center: drone ?? (points.isEmpty ? AppMap.valledupar : points.first),
      fit: points,
      follow: drone,
      fitPadding: EdgeInsets.fromLTRB(56, 140, 56, sheetHeight + 40),
      controlsPadding: EdgeInsets.only(right: 16, bottom: sheetHeight),
      layers: [
        // flutter_map no acepta una línea sin puntos: sin ruta, no hay capa.
        if (points.length >= 2)
          _RouteLayer(points: points, drone: drone, returnLeg: returnLeg),
        if (points.length >= 2)
          returnLeg
              ? _EndpointsLayer(from: points.last, to: points.first)
              : _EndpointsLayer(from: points.first, to: points.last),
        if (drone != null)
          MarkerLayer(
            markers: [
              Marker(
                point: drone!,
                width: DroneMarker.size,
                height: DroneMarker.size,
                child: const DroneMarker(),
              ),
            ],
          ),
      ],
    );
  }
}

/// La central de origen (en vidrio) y el destino (con el acento).
class _EndpointsLayer extends StatelessWidget {
  const _EndpointsLayer({required this.from, required this.to});

  final LatLng from;
  final LatLng to;

  @override
  Widget build(BuildContext context) {
    Marker pin(LatLng point, Widget child) => Marker(
      point: point,
      width: PlacePin.size,
      height: PlacePin.size,
      alignment: Alignment.topCenter,
      child: child,
    );
    return MarkerLayer(
      markers: [
        pin(
          from,
          const PlacePin(
            icon: Icons.home_work_outlined,
            label: 'Central de origen',
          ),
        ),
        pin(
          to,
          const PlacePin(
            icon: Icons.flag_rounded,
            label: 'Destino',
            highlight: true,
          ),
        ),
      ],
    );
  }
}

/// La ruta en dos tramos: hasta el punto más cercano al dron va sólida
/// (recorrida) y desde ahí punteada (lo que falta).
class _RouteLayer extends StatelessWidget {
  const _RouteLayer({
    required this.points,
    required this.drone,
    required this.returnLeg,
  });

  final List<LatLng> points;
  final LatLng? drone;

  /// El regreso va en el color de información, para no confundirlo con la
  /// ida.
  final bool returnLeg;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = returnLeg ? palette.info : palette.accentGradient.first;
    final gradient = returnLeg
        ? [palette.info, palette.info.withValues(alpha: 0.7)]
        : palette.accentGradient;
    final split = _closestIndex();
    final done = points.sublist(0, split + 1);
    final left = points.sublist(split);
    return PolylineLayer(
      polylines: [
        if (left.length >= 2)
          Polyline(
            points: left,
            strokeWidth: 4,
            color: accent.withValues(alpha: 0.55),
            pattern: StrokePattern.dashed(segments: const [10, 8]),
          ),
        if (done.length >= 2)
          Polyline(
            points: done,
            strokeWidth: 5,
            gradientColors: gradient,
            borderStrokeWidth: 6,
            borderColor: accent.withValues(alpha: 0.18),
          ),
      ],
    );
  }

  int _closestIndex() {
    final at = drone;
    if (at == null) return 0;
    const distance = Distance();
    var best = 0;
    for (var i = 1; i < points.length; i++) {
      if (distance(at, points[i]) < distance(at, points[best])) best = i;
    }
    return best;
  }
}
