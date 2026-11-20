import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/geofences/data/geofence_models.dart';

const _square = {
  'type': 'Polygon',
  'coordinates': [
    [
      [-73.25, 10.46],
      [-73.24, 10.46],
      [-73.24, 10.47],
      [-73.25, 10.46],
    ],
  ],
};

void main() {
  test('una zona legal en círculo trae su ficha completa (RF-21, RF-43)', () {
    final zone = Geofence.fromJson({
      'id': 'z1',
      'class': 'prohibited',
      'shape': 'circle',
      'name': 'CAI Hurtado',
      'reason': null,
      'center': {'latitude': 10.5038, 'longitude': -73.2682},
      'radiusM': 100,
      'polygon': _square,
      'code': 'cai-hurtado',
      'legalBasis': 'RAC 100.315(a)(13)',
      'source': 'Equipo AirDrop',
      'active': false,
    });
    expect(zone.isLegal, isTrue);
    expect(zone.isCircle, isTrue);
    expect(zone.radiusM, 100);
    expect(zone.center, const GeoPoint(latitude: 10.5038, longitude: -73.2682));
    expect(zone.active, isFalse);
    expect(zone.geofenceClass.label, 'Prohibida');
  });

  test('una operativa en círculo se envía con centro, radio y categoría', () {
    final body = CreateGeofenceRequest(
      name: 'Obra',
      reason: 'Grúa',
      category: OperationalCategory.works,
      geometry: const GeofenceGeometry.circle(
        center: GeoPoint(latitude: 10.47, longitude: -73.25),
        radiusM: 200,
      ),
    ).toJson();
    expect(body, {
      'name': 'Obra',
      'reason': 'Grúa',
      'category': 'works',
      'shape': 'circle',
      'center': {'latitude': 10.47, 'longitude': -73.25},
      'radiusM': 200,
    });
  });

  test('un polígono se envía como vértices, sin cerrar', () {
    final body = const GeofenceGeometry.polygon([
      GeoPoint(latitude: 10.46, longitude: -73.25),
      GeoPoint(latitude: 10.46, longitude: -73.24),
      GeoPoint(latitude: 10.47, longitude: -73.24),
    ]).toJson();
    expect(body['shape'], 'polygon');
    expect(body['vertices'], hasLength(3));
    expect(body.containsKey('center'), isFalse);
  });

  test('quitar la vigencia envía expiresAt en null', () {
    const request = UpdateGeofenceRequest(clearExpiry: true);
    expect(request.isEmpty, isFalse);
    expect(request.toJson(), {'expiresAt': null});
  });

  test('editar una zona legal siempre lleva el motivo', () {
    const request = UpdateLegalZoneRequest(reason: 'Ajuste', name: 'CAI Norte');
    expect(request.toJson(), {'reason': 'Ajuste', 'name': 'CAI Norte'});
    expect(const UpdateLegalZoneRequest(reason: 'x').hasChanges, isFalse);
  });
}
