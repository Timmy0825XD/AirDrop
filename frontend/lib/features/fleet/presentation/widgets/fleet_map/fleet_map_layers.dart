import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/widgets/app_map.dart';
import '../../../../../theme/app_icons.dart';
import '../../../../../theme/app_palette.dart';
import '../../../../tracking/presentation/widgets/flight_map.dart'
    show closestRouteIndex, routeHeading;
import '../../../data/fleet_flight.dart';
import '../../../data/fleet_map_models.dart';
import 'fleet_map_markers.dart';

/// Las geovallas en rojo translúcido: el corredor no las cruza.
class FleetGeofenceLayer extends StatelessWidget {
  const FleetGeofenceLayer({super.key, required this.geofences});

  final List<FleetMapGeofence> geofences;

  @override
  Widget build(BuildContext context) {
    final danger = Theme.of(context).colorScheme.error;
    return PolygonLayer(
      polygons: [
        for (final fence in geofences)
          if (fence.polygon.ring.length >= 3)
            Polygon(
              points: fence.polygon.ring.map(latLngFromGeoJson).toList(),
              color: danger.withValues(alpha: 0.14),
              borderColor: danger.withValues(alpha: 0.8),
              borderStrokeWidth: 2,
            ),
      ],
    );
  }
}

/// El corredor que vuela cada dron: la ida en el acento, el regreso en el
/// color de información.
class FleetRoutesLayer extends StatelessWidget {
  const FleetRoutesLayer({super.key, required this.flights});

  final List<FleetFlight> flights;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final info = context.palette.info;
    return PolylineLayer(
      polylines: [
        for (final f in flights)
          if (f.activeRoute.length >= 2)
            Polyline(
              points: f.activeRoute.map(latLngFromGeoJson).toList(),
              strokeWidth: 3,
              pattern: StrokePattern.dashed(segments: const [8, 6]),
              color: (f.returning ? info : primary).withValues(alpha: 0.75),
            ),
      ],
    );
  }
}

/// Las centrales del operador con la cruz médica.
class FleetHubsLayer extends StatelessWidget {
  const FleetHubsLayer({super.key, required this.hubs});

  final List<FleetMapHub> hubs;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        for (final hub in hubs)
          Marker(
            point: LatLng(hub.latitude, hub.longitude),
            width: FleetHubPin.width,
            height: FleetHubPin.height,
            child: FleetHubPin(hub: hub),
          ),
      ],
    );
  }
}

/// Cada dron apuntando hacia donde va; tenue si perdió el enlace. Tocarlo
/// abre su ficha.
class FleetDronesLayer extends StatelessWidget {
  const FleetDronesLayer({
    super.key,
    required this.flights,
    required this.onDrone,
  });

  final List<FleetFlight> flights;
  final ValueChanged<FleetFlight> onDrone;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        for (final f in flights)
          if (f.hasPosition) _marker(f),
      ],
    );
  }

  Marker _marker(FleetFlight f) {
    final at = LatLng(f.latitude!, f.longitude!);
    final route = f.activeRoute.map(latLngFromGeoJson).toList();
    return Marker(
      point: at,
      width: FleetDronePin.width,
      height: FleetDronePin.height,
      child: FleetDronePin(
        flight: f,
        onTap: () => onDrone(f),
        heading: routeHeading(route, closestRouteIndex(route, at)),
      ),
    );
  }
}

/// Dónde bajó un dron con un incidente abierto (RF-34).
class FleetIncidentsLayer extends StatelessWidget {
  const FleetIncidentsLayer({super.key, required this.incidents});

  final List<FleetIncident> incidents;

  @override
  Widget build(BuildContext context) {
    final danger = context.palette.danger;
    return MarkerLayer(
      markers: [
        for (final i in incidents)
          if (i.latitude != null && i.longitude != null)
            Marker(
              point: LatLng(i.latitude!, i.longitude!),
              width: 36,
              height: 36,
              child: Tooltip(
                message: i.protocolLabel,
                child: Icon(AppIcons.warning, color: danger, size: 30),
              ),
            ),
      ],
    );
  }
}
