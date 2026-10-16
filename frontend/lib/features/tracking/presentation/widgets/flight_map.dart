import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/widgets/app_map.dart';

/// El mapa del vuelo: la ruta del pedido y el dron encima de [AppMap].
///
/// La ruta llega como pares `[longitud, latitud]` (GeoJSON) y aquí se
/// voltea a `LatLng(latitud, longitud)`, que es lo que pide el mapa.
class FlightMap extends StatelessWidget {
  const FlightMap({super.key, required this.route, this.drone});

  /// Puntos del corredor, `[longitud, latitud]`.
  final List<List<double>> route;

  /// Posición actual del dron; `null` mientras no hay vuelo.
  final LatLng? drone;

  @override
  Widget build(BuildContext context) {
    final points = route.map(latLngFromGeoJson).toList();
    final colors = Theme.of(context).colorScheme;
    return AppMap(
      center: drone ?? (points.isEmpty ? AppMap.valledupar : points.first),
      // Encuadra la ruta completa al abrir, con aire alrededor.
      fit: points,
      layers: [
        // flutter_map no acepta una línea sin puntos: sin ruta, no hay capa.
        if (points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(points: points, strokeWidth: 4, color: colors.primary),
            ],
          ),
        if (drone != null)
          MarkerLayer(
            markers: [
              Marker(
                point: drone!,
                width: 36,
                height: 36,
                child: const _DroneMarker(),
              ),
            ],
          ),
      ],
    );
  }
}

/// El dron en el mapa: el naranja de señal con borde blanco.
class _DroneMarker extends StatelessWidget {
  const _DroneMarker();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Dron',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: colors.secondary.withValues(alpha: 0.5),
              blurRadius: 12,
            ),
          ],
        ),
        child: const Icon(Icons.flight_rounded, size: 18, color: Colors.white),
      ),
    );
  }
}
