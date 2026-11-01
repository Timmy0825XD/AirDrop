import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_map.dart';
import '../../../../core/widgets/map_hud_overlay.dart';
import '../../../../core/widgets/map_markers.dart';
import '../../../../theme/app_palette.dart';

/// El punto de la ruta más cercano al dron (0 sin dron): hasta ahí va lo
/// recorrido. También lo usa la hoja para la barra de avance.
int closestRouteIndex(List<LatLng> points, LatLng? at) {
  if (at == null || points.isEmpty) return 0;
  const distance = Distance();
  var best = 0;
  for (var i = 1; i < points.length; i++) {
    if (distance(at, points[i]) < distance(at, points[best])) best = i;
  }
  return best;
}

/// El rumbo del tramo donde va el dron, en radianes desde el norte.
double routeHeading(List<LatLng> points, int split) {
  if (points.length < 2) return 0;
  final i = math.min(split, points.length - 2);
  final degrees = const Distance().bearing(points[i], points[i + 1]);
  return degrees * math.pi / 180;
}

/// El mapa del vuelo, a pantalla completa, como una pantalla de
/// navegación: sobre los tiles va la grilla de vuelo con los bordes
/// apagados; encima la ruta (lo recorrido luminoso, lo que falta
/// punteado, todo sobre un corredor tenue), la central con la cruz médica,
/// el destino como un blanco y el dron apuntando hacia donde va, que la
/// cámara acompaña. En el regreso ([returnLeg]) pinta la ruta de vuelta
/// (`assignment.returnRoute`), que va del destino a la central.
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
    final split = closestRouteIndex(points, drone);
    return AppMap(
      // El encuadre solo aplica al crear el mapa: si la ruta llega después
      // (el pedido aún cargaba), se vuelve a montar para encuadrarla.
      key: ValueKey(points.length >= 2),
      center: drone ?? (points.isEmpty ? AppMap.valledupar : points.first),
      fit: points,
      follow: drone,
      fitPadding: EdgeInsets.fromLTRB(56, 150, 56, sheetHeight + 40),
      controlsPadding: EdgeInsets.only(right: 16, bottom: sheetHeight),
      layers: [
        const MapHudOverlay(),
        // flutter_map no acepta una línea sin puntos: sin ruta, no hay capa.
        if (points.length >= 2)
          _RouteLayer(points: points, split: split, returnLeg: returnLeg),
        if (points.length >= 2)
          returnLeg
              ? _EndpointsLayer(hub: points.last, target: points.first)
              : _EndpointsLayer(hub: points.first, target: points.last),
        if (drone != null)
          MarkerLayer(
            markers: [
              Marker(
                point: drone!,
                width: DroneMarker.size,
                height: DroneMarker.size,
                child: DroneMarker(heading: routeHeading(points, split)),
              ),
            ],
          ),
      ],
    );
  }
}

/// La central de origen y el destino.
class _EndpointsLayer extends StatelessWidget {
  const _EndpointsLayer({required this.hub, required this.target});

  final LatLng hub;
  final LatLng target;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: hub,
          width: HubMarker.size,
          height: HubMarker.size,
          child: const HubMarker(),
        ),
        Marker(
          point: target,
          width: TargetMarker.size,
          height: TargetMarker.size,
          child: const TargetMarker(),
        ),
      ],
    );
  }
}

/// La ruta en dos tramos sobre un corredor tenue: hasta [split] (el punto
/// más cercano al dron) va luminosa, con su brillo; desde ahí, punteada.
class _RouteLayer extends StatelessWidget {
  const _RouteLayer({
    required this.points,
    required this.split,
    required this.returnLeg,
  });

  final List<LatLng> points;
  final int split;

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
    final done = points.sublist(0, split + 1);
    final left = points.sublist(split);
    return PolylineLayer(
      polylines: [
        Polyline(
          points: points,
          strokeWidth: 14,
          color: accent.withValues(alpha: 0.07),
        ),
        if (left.length >= 2)
          Polyline(
            points: left,
            strokeWidth: 3,
            color: accent.withValues(alpha: 0.55),
            pattern: StrokePattern.dashed(segments: const [8, 9]),
          ),
        if (done.length >= 2) ...[
          Polyline(
            points: done,
            strokeWidth: 12,
            color: accent.withValues(alpha: 0.22),
          ),
          Polyline(points: done, strokeWidth: 4.5, gradientColors: gradient),
        ],
      ],
    );
  }
}
