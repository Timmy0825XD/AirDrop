import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// El mapa de la app: tiles de OpenStreetMap y su crédito. Encima van las
/// capas de cada pantalla (la ruta y el dron del vuelo, el polígono de una
/// geovalla). No abre sockets ni pide datos.
class AppMap extends StatelessWidget {
  const AppMap({
    super.key,
    required this.layers,
    this.center = valledupar,
    this.fit = const [],
    this.onTap,
    this.interactive = true,
  });

  /// Centro por defecto: el caso de estudio es Valledupar.
  static const valledupar = LatLng(10.4631, -73.2532);

  final List<Widget> layers;
  final LatLng center;

  /// Puntos que deben quedar a la vista al abrir; con menos de 2 se usa
  /// [center].
  final List<LatLng> fit;

  final void Function(LatLng point)? onTap;

  /// `false` deja el mapa quieto (vista previa dentro de un formulario).
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        initialCameraFit: fit.length < 2
            ? null
            : CameraFit.coordinates(
                coordinates: fit,
                padding: const EdgeInsets.all(48),
              ),
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onTap: onTap == null ? null : (_, point) => onTap!(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // La política de uso de los tiles de OSM exige identificar la app.
          userAgentPackageName: 'com.example.frontend',
        ),
        ...layers,
        const SimpleAttributionWidget(source: Text('OpenStreetMap')),
      ],
    );
  }
}

/// GeoJSON guarda `[longitud, latitud]`; el mapa pide `LatLng(lat, lng)`.
LatLng latLngFromGeoJson(List<double> point) => LatLng(point[1], point[0]);

/// Lo contrario, redondeado a 6 decimales (unos 10 cm): un toque en el
/// mapa no necesita más precisión y el body queda legible.
List<double> geoJsonFromLatLng(LatLng point) => [
  double.parse(point.longitude.toStringAsFixed(6)),
  double.parse(point.latitude.toStringAsFixed(6)),
];
