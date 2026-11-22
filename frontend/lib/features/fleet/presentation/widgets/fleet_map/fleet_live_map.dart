import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/widgets/app_map.dart';
import '../../../data/fleet_flight.dart';
import '../../../data/fleet_map_models.dart';
import 'fleet_legal_zone_layer.dart';
import 'fleet_map_layers.dart';

/// El mapa en vivo del operador: sus centrales, las geovallas, el corredor
/// y la posición de cada dron, y dónde bajó uno con un incidente. Encuadra
/// las centrales y rutas al abrir; la hoja de abajo lo deja libre.
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final hubs = [for (final h in map.hubs) LatLng(h.latitude, h.longitude)];
      final points = [
        ...hubs,
        for (final flight in map.flights) ...[
          if (flight.hasPosition) LatLng(flight.latitude!, flight.longitude!),
          ...flight.activeRoute.map(latLngFromGeoJson),
        ],
      ];
      final top =
          MediaQuery.paddingOf(context).top +
          MediaQuery.textScalerOf(context).scale(14) * 4 +
          52;
      return AppMap(
        // El encuadre solo aplica al crear el mapa: se monta de nuevo cuando
        // llegan las centrales.
        key: ValueKey(map.hubs.map((hub) => hub.id).join(',')),
        center: hubs.isEmpty ? AppMap.valledupar : hubs.first,
        fit: points,
        zoom: 13,
        fitPadding: EdgeInsets.fromLTRB(80, top + 16, 80, sheetHeight + 40),
        controlsPadding: EdgeInsets.only(
          top: top,
          right: 16,
          bottom: sheetHeight,
        ),
        // Los tres controles necesitan 152 dp; al expandir la hoja queda
        // disponible el gesto del mapa y reaparecen al bajar la hoja.
        showControls: box.maxHeight - top - sheetHeight >= 152,
        layers: [
          const FleetLegalZoneLayer(),
          FleetGeofenceLayer(geofences: map.geofences),
          FleetRoutesLayer(flights: map.flights),
          FleetHubsLayer(hubs: map.hubs),
          FleetIncidentsLayer(incidents: incidents),
          FleetDronesLayer(flights: map.flights, onDrone: onDrone),
        ],
      );
    },
  );
}
