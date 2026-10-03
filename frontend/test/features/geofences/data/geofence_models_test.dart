import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/geofences/data/geofence_models.dart';

void main() {
  test('fromVertices cierra el anillo copiando el primer punto', () {
    final polygon = GeoJsonPolygon.fromVertices([
      [-73.26, 10.46],
      [-73.24, 10.46],
      [-73.25, 10.48],
    ]);

    final ring = polygon.coordinates.first;
    expect(ring, hasLength(4), reason: '3 vértices + el cierre');
    expect(ring.first, [-73.26, 10.46]);
    expect(ring.last, [-73.26, 10.46], reason: 'primero == último');
    expect(
      ring.first,
      isNot(same(ring.last)),
      reason: 'el cierre es una copia, no la misma lista',
    );
  });

  test('con menos de 3 vértices no se inventa geometría', () {
    final polygon = GeoJsonPolygon.fromVertices([
      [-73.26, 10.46],
      [-73.24, 10.46],
    ]);

    expect(
      polygon.coordinates.first,
      hasLength(2),
      reason: 'Nest responde con su mensaje de anillo',
    );
  });

  test('fromVertices no duplica el cierre si el anillo ya viene cerrado', () {
    final polygon = GeoJsonPolygon.fromVertices([
      [-73.26, 10.46],
      [-73.24, 10.46],
      [-73.25, 10.48],
      [-73.26, 10.46],
    ]);

    expect(polygon.coordinates.first, hasLength(4));
  });

  test('vertices devuelve el anillo sin repetir el cierre', () {
    const polygon = GeoJsonPolygon([
      [
        [-73.26, 10.46],
        [-73.24, 10.46],
        [-73.25, 10.48],
        [-73.26, 10.46],
      ],
    ]);

    expect(polygon.vertices, hasLength(3));
    expect(polygon.vertices.first, [-73.26, 10.46]);
    // Al editar y volver a guardar, fromVertices rearmo el cierre.
    final again = GeoJsonPolygon.fromVertices(polygon.vertices);
    expect(again.coordinates.first, hasLength(4));
  });

  test('hasSameRing compara puntos, no identidad de listas', () {
    GeoJsonPolygon polygon() => GeoJsonPolygon.fromVertices([
      [-73.26, 10.46],
      [-73.24, 10.46],
      [-73.25, 10.48],
    ]);

    expect(polygon().hasSameRing(polygon()), isTrue);

    final moved = GeoJsonPolygon.fromVertices([
      [-73.26, 10.46],
      [-73.23, 10.46], // un vértice corrido
      [-73.25, 10.48],
    ]);
    expect(polygon().hasSameRing(moved), isFalse);
    expect(
      GeoJsonPolygon(const []).hasSameRing(polygon()),
      isFalse,
      reason: 'un anillo vacío no es el mismo que el del formulario',
    );
  });

  test('fromJson lee coordinates[0] como [longitud, latitud]', () {
    final polygon = GeoJsonPolygon.fromJson({
      'type': 'Polygon',
      'coordinates': [
        [
          [-73.26, 10.46],
          [-73.24, 10.46],
          [-73.25, 10.48],
          [-73.26, 10.46],
        ],
      ],
    });

    expect(polygon.ring, hasLength(4));
    expect(polygon.ring.first, [-73.26, 10.46]);
    expect(polygon.ring.first.first, isA<double>());
  });

  test('fromJson convierte los enteros de GeoJSON en doubles', () {
    final polygon = GeoJsonPolygon.fromJson({
      'type': 'Polygon',
      'coordinates': [
        [
          [-73, 10],
          [-72, 10],
          [-72, 11],
          [-73, 10],
        ],
      ],
    });

    expect(polygon.ring.first, [-73.0, 10.0]);
  });

  test('fromJson sin coordenadas lanza FormatException', () {
    expect(
      () => GeoJsonPolygon.fromJson({'type': 'Polygon'}),
      throwsFormatException,
    );
  });

  test('toJson mantiene el anillo en coordinates[0]', () {
    const polygon = GeoJsonPolygon([
      [
        [-73.26, 10.46],
        [-73.24, 10.46],
        [-73.25, 10.48],
        [-73.26, 10.46],
      ],
    ]);

    final json = polygon.toJson();
    expect(json['type'], 'Polygon');
    expect(json['coordinates'], [
      [
        [-73.26, 10.46],
        [-73.24, 10.46],
        [-73.25, 10.48],
        [-73.26, 10.46],
      ],
    ]);
  });

  test('el PATCH lleva solo los campos cambiados', () {
    const empty = UpdateGeofenceRequest();
    expect(empty.isEmpty, isTrue);
    expect(empty.toJson(), isEmpty);

    const changed = UpdateGeofenceRequest(name: ' Nuevo nombre ');
    expect(changed.toJson(), {'name': ' Nuevo nombre '});
  });

  test('Geofence.fromJson lee la fila de Nest', () {
    final geofence = Geofence.fromJson({
      'id': 'e1111111-1111-4111-8111-111111111111',
      'name': 'Corredor Aéreo',
      'reason': 'Pasillo aéreo',
      'polygon': {
        'type': 'Polygon',
        'coordinates': [
          [
            [-73.26, 10.46],
            [-73.24, 10.46],
            [-73.25, 10.48],
            [-73.26, 10.46],
          ],
        ],
      },
      'createdByUserId': '33333333-3333-4333-8333-333333333333',
      'createdAt': '2026-09-01T12:00:00.000Z',
    });

    expect(geofence.name, 'Corredor Aéreo');
    expect(geofence.polygon.vertices, hasLength(3));
    expect(geofence.createdByUserId, '33333333-3333-4333-8333-333333333333');
    expect(geofence.createdAt, DateTime.utc(2026, 9, 1, 12));
  });
}
