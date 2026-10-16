import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/geofences/data/geofence_models.dart';
import 'package:frontend/features/geofences/presentation/widgets/geofence_form_values.dart';

Geofence _geofence() => Geofence(
  id: 'e2222222-2222-4222-8222-222222222222',
  name: 'Zona Restricción Hospital General',
  reason: 'Vertiginoso: sin vuelo a baja altura sobre el hospital',
  polygon: GeoJsonPolygon.fromVertices([
    [-73.26, 10.46],
    [-73.24, 10.46],
    [-73.25, 10.48],
  ]),
);

/// Lo que devuelve el modo dibujar con tres toques.
void _fillThree(GeofenceFormValues values) {
  values.vertices = [
    [-73.26, 10.46],
    [-73.24, 10.46],
    [-73.25, 10.48],
  ];
}

void main() {
  test('arranca sin vértices: se dibujan en el mapa', () {
    final values = GeofenceFormValues();
    addTearDown(values.dispose);

    expect(values.vertices, isEmpty);
  });

  group('request (POST /geofences)', () {
    test('arma el body con el anillo cerrado y sin hubId', () {
      final values = GeofenceFormValues();
      addTearDown(values.dispose);
      values
        ..name.text = '  Zona Norte  '
        ..reason.text = '  Vuelo restringido  ';
      _fillThree(values);

      final body = values.request();

      expect(body.toJson(), {
        'name': 'Zona Norte',
        'reason': 'Vuelo restringido',
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
      });
      expect(body.toJson(), isNot(contains('hubId')));
    });

    test('un cuarto vértice también cierra el anillo', () {
      final values = GeofenceFormValues();
      addTearDown(values.dispose);
      _fillThree(values);
      values.vertices.add([-73.2, 10.5]);

      final ring = values.request().polygon.ring;

      expect(ring, hasLength(5));
      expect(ring.first, ring.last);
    });
  });

  group('diff (PATCH /geofences/:id)', () {
    test('sin cambios queda vacío: la pantalla no envía el PATCH', () {
      final values = GeofenceFormValues()..load(_geofence());

      final request = values.diff(_geofence());

      expect(request.isEmpty, isTrue);
      expect(request.toJson(), isEmpty);
    });

    test('solo incluye los campos que cambiaron', () {
      final values = GeofenceFormValues()..load(_geofence());
      values.reason.text = '  Corredor ampliado  ';

      final request = values.diff(_geofence());

      expect(request.isEmpty, isFalse);
      expect(request.toJson(), {'reason': 'Corredor ampliado'});
    });

    test('mover un vértice cambia solo el polígono', () {
      final values = GeofenceFormValues()..load(_geofence());
      values.vertices = [
        [-73.26, 10.46],
        [-73.23, 10.46],
        [-73.25, 10.48],
      ];

      final request = values.diff(_geofence());

      expect(request.name, isNull);
      expect(request.reason, isNull);
      expect(request.polygon, isNotNull);
      expect(request.polygon!.ring.first, [
        -73.26,
        10.46,
      ], reason: 'el cierre sigue siendo el primer punto');
    });
  });

  test('load rellena el formulario sin repetir el cierre', () {
    final values = GeofenceFormValues();
    addTearDown(values.dispose);

    values.load(_geofence());

    expect(values.name.text, 'Zona Restricción Hospital General');
    expect(
      values.reason.text,
      'Vertiginoso: sin vuelo a baja altura sobre el hospital',
    );
    expect(
      values.vertices,
      hasLength(3),
      reason: 'el anillo de 4 cierra con el primero, que no se edita',
    );
    expect(values.vertices.first, [-73.26, 10.46]);
  });
}
