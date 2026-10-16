import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Mapa de OpenStreetMap con la ruta del pedido y el dron encima.
///
/// La ruta llega como pares `[longitud, latitud]` (GeoJSON) y aquí se
/// voltea a `LatLng(latitud, longitud)`, que es lo que pide el mapa.
class FlightMap extends StatelessWidget {
  const FlightMap({super.key, required this.route, this.drone});

  /// Valledupar, por si todavía no hay ruta ni dron.
  static const _valledupar = LatLng(10.4631, -73.2532);

  /// Puntos del corredor, `[longitud, latitud]`.
  final List<List<double>> route;

  /// Posición actual del dron; `null` mientras no hay vuelo.
  final LatLng? drone;

  @override
  Widget build(BuildContext context) {
    final points = [for (final p in route) LatLng(p[1], p[0])];
    final colors = Theme.of(context).colorScheme;
    return FlutterMap(
      options: MapOptions(
        initialCenter: drone ?? (points.isEmpty ? _valledupar : points.first),
        initialZoom: 14,
        // Encuadra la ruta completa al abrir, con aire alrededor.
        initialCameraFit: points.length < 2
            ? null
            : CameraFit.coordinates(
                coordinates: points,
                padding: const EdgeInsets.all(48),
              ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // La política de uso de los tiles de OSM exige identificar la app.
          userAgentPackageName: 'com.example.frontend',
        ),
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
        const SimpleAttributionWidget(source: Text('OpenStreetMap')),
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
