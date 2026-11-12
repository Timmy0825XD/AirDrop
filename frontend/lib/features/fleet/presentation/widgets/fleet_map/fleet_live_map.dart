import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/widgets/app_map.dart';
import '../../../data/fleet_flight.dart';
import '../../../data/fleet_map_models.dart';
import 'fleet_map_layers.dart';

/// El mapa en vivo del operador: sus centrales, las geovallas, el corredor
/// y la posición de cada dron, y dónde bajó uno con un incidente. Encuadra
/// las centrales al abrir; la hoja de abajo lo deja libre.
class FleetLiveMap extends StatelessWidget {
  const FleetLiveMap({
    super.key,
    required this.map,
    required this.incidents,
    required this.sheetHeight,
    required this.onDrone,
  });

  final FleetMap map;
  final List<FleetIncident> incidents;
  final double sheetHeight;
  final ValueChanged<FleetFlight> onDrone;

  @override
  Widget build(BuildContext context) {
    final hubs = [for (final h in map.hubs) LatLng(h.latitude, h.longitude)];
    return AppMap(
      // El encuadre solo aplica al crear el mapa: se monta de nuevo cuando
      // llegan las centrales.
      key: ValueKey(hubs.length),
      center: hubs.isEmpty ? AppMap.valledupar : hubs.first,
      fit: hubs.length >= 2 ? hubs : const [],
      zoom: 13,
      fitPadding: EdgeInsets.fromLTRB(56, 150, 56, sheetHeight + 40),
      controlsPadding: EdgeInsets.only(right: 16, bottom: sheetHeight),
      layers: [
        FleetGeofenceLayer(geofences: map.geofences),
        FleetRoutesLayer(flights: map.flights),
        FleetHubsLayer(hubs: map.hubs),
        FleetIncidentsLayer(incidents: incidents),
        FleetDronesLayer(flights: map.flights, onDrone: onDrone),
      ],
    );
  }
}
