import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/core/auth/token_store.dart';
import 'package:frontend/features/auth/data/local/local_auth_rules.dart';
import 'package:frontend/features/geofences/data/geofence_models.dart';
import 'package:frontend/features/geofences/data/local_geofence_repository.dart';

/// Sesión simulada del operador de flota: la única cuenta que
/// `GeofencesController` acepta (`@Roles(FLEET_OPERATOR)`).
const String _operatorSession =
    '${LocalAuthRules.tokenPrefix}33333333-3333-4333-8333-333333333333';

const String _fixtureGeofenceId = 'e2222222-2222-4222-8222-222222222222';

class _FakeTokenStore extends TokenStore {
  _FakeTokenStore([this.value]);

  final String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> delete() async {}
}

LocalGeofenceRepository _repo({String? token = _operatorSession}) =>
    LocalGeofenceRepository(tokenStore: _FakeTokenStore(token));

GeoJsonPolygon _triangle() => GeoJsonPolygon.fromVertices([
  [-73.26, 10.46],
  [-73.24, 10.46],
  [-73.25, 10.48],
]);

CreateGeofenceRequest _request({
  String name = 'Zona Norte',
  String reason = 'Vuelo restringido por la pista',
}) => CreateGeofenceRequest(name: name, reason: reason, polygon: _triangle());

/// Los mensajes y códigos son los de `GeofencesService` en Nest.
void main() {
  test('sin una sesión activa Nest responde 401, no 403', () async {
    final repo = _repo(token: 'local-session:otro-usuario');

    await expectLater(
      repo.list(),
      _message(401, 'Tu sesión expiró. Inicia sesión de nuevo.'),
    );
    await expectLater(
      repo.create(_request()),
      _message(401, 'Tu sesión expiró. Inicia sesión de nuevo.'),
    );
  });

  test('sin token la maqueta local también responde 401', () async {
    final repo = _repo(token: null);

    await expectLater(
      repo.list(),
      _message(401, 'Tu sesión expiró. Inicia sesión de nuevo.'),
    );
  });

  test('list trae las fixtures ordenadas por nombre, como Nest', () async {
    final rows = await _repo().list();

    expect(rows.map((geofence) => geofence.name), [
      'Corredor Aéreo Ambulancia',
      'Zona Restricción Hospital General',
    ]);
    expect(
      rows.first.polygon.ring,
      hasLength(5),
      reason: 'las fixtures vienen cerradas (primero == último)',
    );
  });

  test(
    'crear una geovalla la agrega al listado con el nombre recortado',
    () async {
      final repo = _repo();

      final geofence = await repo.create(_request(name: '  Zona Norte  '));

      expect(geofence.name, 'Zona Norte');
      expect(geofence.reason, 'Vuelo restringido por la pista');
      expect(
        geofence.polygon.ring,
        hasLength(4),
        reason: 'el cliente cierra el anillo',
      );
      expect(geofence.createdByUserId, '33333333-3333-4333-8333-333333333333');
      final rows = await repo.list();
      expect(rows.map((row) => row.name), contains('Zona Norte'));
    },
  );

  test(
    'un anillo con menos de 4 puntos responde 400 con el mensaje de Nest',
    () async {
      final repo = _repo();
      final open = GeoJsonPolygon.fromVertices([
        [-73.26, 10.46],
        [-73.24, 10.46],
      ]);

      await expectLater(
        repo.create(
          CreateGeofenceRequest(
            name: 'Zona Norte',
            reason: 'Vuelo restringido',
            polygon: open,
          ),
        ),
        _message(
          400,
          'El polígono necesita al menos 4 puntos y debe estar cerrado.',
        ),
      );
    },
  );

  test('un anillo de 4 puntos sin cerrar responde 400', () async {
    final repo = _repo();
    const unclosed = GeoJsonPolygon([
      [
        [-73.26, 10.46],
        [-73.24, 10.46],
        [-73.25, 10.48],
        [-73.2, 10.5],
      ],
    ]);

    await expectLater(
      repo.create(
        CreateGeofenceRequest(
          name: 'Zona Norte',
          reason: 'Vuelo restringido',
          polygon: unclosed,
        ),
      ),
      _message(
        400,
        'El primer y el último punto del polígono deben coincidir.',
      ),
    );
  });

  test('un punto fuera de rango responde 400', () async {
    final repo = _repo();
    const badPoint = GeoJsonPolygon([
      [
        [-73.26, 10.46],
        [-200, 10.46],
        [-73.25, 10.48],
        [-73.26, 10.46],
      ],
    ]);

    await expectLater(
      repo.create(
        CreateGeofenceRequest(
          name: 'Zona Norte',
          reason: 'Vuelo restringido',
          polygon: badPoint,
        ),
      ),
      _message(
        400,
        'Cada punto debe ser [longitud, latitud] con rangos válidos.',
      ),
    );
  });

  test('un nombre sobre 80 caracteres responde 400', () async {
    final repo = _repo();

    await expectLater(
      repo.create(_request(name: List.filled(81, 'N').join())),
      _message(400, 'El nombre no puede superar 80 caracteres.'),
    );
  });

  test('un motivo sobre 160 caracteres responde 400 en el PATCH', () async {
    final repo = _repo();

    await expectLater(
      repo.update(
        _fixtureGeofenceId,
        UpdateGeofenceRequest(reason: List.filled(161, 'm').join()),
      ),
      _message(400, 'El motivo no puede superar 160 caracteres.'),
    );
  });

  test(
    'un nombre en blanco no da 400: Nest solo exige que sea string',
    () async {
      final repo = _repo();

      final geofence = await repo.create(_request(name: '   '));

      expect(geofence.name, '', reason: 'GeofencesService guarda name.trim()');
    },
  );

  test('actualizar una geovalla inexistente responde 404', () async {
    final repo = _repo();

    await expectLater(
      repo.update(
        'ffffffff-ffff-4fff-8fff-ffffffffffff',
        const UpdateGeofenceRequest(name: 'Otra'),
      ),
      _message(404, 'La geovalla no existe.'),
    );
  });

  test(
    'un PATCH sin campos responde 400 antes de buscar la geovalla',
    () async {
      final repo = _repo();

      await expectLater(
        repo.update(
          'ffffffff-ffff-4fff-8fff-ffffffffffff',
          const UpdateGeofenceRequest(),
        ),
        _message(400, 'Debes enviar al menos un campo para actualizar.'),
      );
    },
  );

  test('el PATCH solo cambia lo que llega y recorta el nombre', () async {
    final repo = _repo();
    final before = (await repo.list()).firstWhere(
      (row) => row.id == _fixtureGeofenceId,
    );

    final updated = await repo.update(
      _fixtureGeofenceId,
      const UpdateGeofenceRequest(name: '  Zona Restricción Ampliada  '),
    );

    expect(updated.name, 'Zona Restricción Ampliada');
    expect(updated.reason, before.reason, reason: 'no se envió, no cambia');
    expect(updated.polygon.coordinates, before.polygon.coordinates);
    expect(updated.id, before.id);
    expect(updated.createdAt, before.createdAt);
  });

  test('borrar quita la geovalla y repetir el borrado responde 404', () async {
    final repo = _repo();
    final before = await repo.list();
    expect(before, hasLength(2));

    await repo.remove(_fixtureGeofenceId);

    final rows = await repo.list();
    expect(rows.map((row) => row.name), ['Corredor Aéreo Ambulancia']);

    await expectLater(
      repo.remove(_fixtureGeofenceId),
      _message(404, 'La geovalla no existe.'),
    );
  });
}

/// Igual que `expectLater(..., throwsA(...))` con los dos atributos que
/// la UI lee de un `ApiException`.
Matcher _message(int statusCode, String message) {
  return throwsA(
    isA<ApiException>()
        .having((e) => e.statusCode, 'statusCode', statusCode)
        .having((e) => e.message, 'message', message),
  );
}
