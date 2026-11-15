import 'package:latlong2/latlong.dart';

import 'delivery_point_models.dart';

/// Puntos de entrega de `DataSource.local`: cuatro de los del escenario
/// (`backend/src/airspace/regional-network.ts`).
const localDeliveryPoints = [
  DeliveryPoint(
    id: 'd1111111-1111-4111-8111-111111111111',
    name: 'Puesto de salud de Badillo',
    municipality: 'Valledupar',
    location: LatLng(10.6314, -73.1279),
  ),
  DeliveryPoint(
    id: 'd2222222-2222-4222-8222-222222222222',
    name: 'Puesto de salud de Guacoche',
    municipality: 'Valledupar',
    location: LatLng(10.4964, -73.166),
  ),
  DeliveryPoint(
    id: 'd3333333-3333-4333-8333-333333333333',
    name: 'Puesto de salud de Atánquez',
    municipality: 'Valledupar',
    location: LatLng(10.6976, -73.3545),
    corridorZone: 'Resguardo Kankuamo',
  ),
  DeliveryPoint(
    id: 'd4444444-4444-4444-8444-444444444444',
    name: 'Puesto de salud de Media Luna',
    municipality: 'San Diego',
    location: LatLng(10.2455, -73.1439),
  ),
];

/// El punto de referencia del aeropuerto y el radio de su anillo (9 km):
/// ahí adentro no se entrega con dron.
const _airport = LatLng(10.43513, -73.2494);
const _ringKm = 9.0;

const _urbanMessage =
    'En la ciudad de Valledupar no se entrega con dron: está dentro del '
    'anillo del aeropuerto. Puedes recoger el medicamento en una central '
    'cercana.';

DeliveryPoint? localPoint(String id) {
  for (final point in localDeliveryPoints) {
    if (point.id == id) return point;
  }
  return null;
}

/// Lo que Nest guarda como dirección: el nombre del punto y su municipio.
String localPointAddress(String id) {
  final point = localPoint(id);
  return point == null
      ? 'Punto de entrega'
      : '${point.name}, ${point.municipality}';
}

/// Como `GET /delivery-points`: los puntos por distancia y el más cercano;
/// dentro del anillo del aeropuerto no hay cobertura.
CoverageResult localCoverage(LatLng? from) {
  if (from == null) {
    return const CoverageResult(
      coverage: Coverage.covered,
      points: localDeliveryPoints,
    );
  }
  const distance = Distance();
  if (distance.as(LengthUnit.Meter, from, _airport) < _ringKm * 1000) {
    return const CoverageResult(
      coverage: Coverage.urban,
      message: _urbanMessage,
    );
  }
  final ranked = [
    for (final point in localDeliveryPoints)
      DeliveryPoint(
        id: point.id,
        name: point.name,
        municipality: point.municipality,
        location: point.location,
        corridorZone: point.corridorZone,
        distanceKm: distance.as(LengthUnit.Meter, from, point.location) / 1000,
      ),
  ]..sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
  return CoverageResult(
    coverage: Coverage.covered,
    nearestPointId: ranked.first.id,
    points: ranked,
  );
}
