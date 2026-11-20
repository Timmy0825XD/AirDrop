import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/core/auth/token_store.dart';
import 'package:frontend/features/auth/data/local/local_auth_rules.dart';
import 'package:frontend/features/geofences/data/geofence_models.dart';
import 'package:frontend/features/geofences/data/local_geofence_repository.dart';

const String _session =
    '${LocalAuthRules.tokenPrefix}33333333-3333-4333-8333-333333333333';
const String _operationalId = 'e1111111-1111-4111-8111-111111111111';
const String _legalId = 'e3333333-3333-4333-8333-333333333333';

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

LocalGeofenceRepository _repo({String? token = _session}) =>
    LocalGeofenceRepository(tokenStore: _FakeTokenStore(token));

Matcher _apiError(String message, int status) => isA<ApiException>()
    .having((e) => e.message, 'message', message)
    .having((e) => e.statusCode, 'statusCode', status);

void main() {
  test('el catálogo trae legales y operativas', () async {
    final rows = await _repo().list();
    expect(rows.where((g) => g.isLegal), hasLength(2));
    expect(rows.where((g) => g.isOperational), hasLength(1));
  });

  test('sin sesión responde 401', () async {
    await expectLater(_repo(token: null).list(), throwsA(isA<ApiException>()));
  });

  test('crear una operativa en círculo guarda centro y radio', () async {
    final repo = _repo();
    final fence = await repo.create(
      const CreateGeofenceRequest(
        name: 'Obra',
        reason: 'Grúa',
        category: OperationalCategory.works,
        geometry: GeofenceGeometry.circle(
          center: GeoPoint(latitude: 10.47, longitude: -73.25),
          radiusM: 300,
        ),
      ),
    );
    expect(fence.isOperational, isTrue);
    expect(fence.radiusM, 300);
    expect(fence.polygon.vertices, hasLength(16));
  });

  test('una zona legal no se edita ni se borra por la vía operativa', () async {
    final repo = _repo();
    await expectLater(
      repo.update(_legalId, const UpdateGeofenceRequest(name: 'x')),
      throwsA(_apiError('La geovalla no existe.', 404)),
    );
    await expectLater(
      repo.remove(_legalId),
      throwsA(_apiError('La geovalla no existe.', 404)),
    );
  });

  test('desactivar deja historial y repetirlo responde 409', () async {
    final repo = _repo();
    final zone = await repo.setLegalActive(
      _legalId,
      active: false,
      reason: 'Cerró el CAI',
    );
    expect(zone.active, isFalse);
    final history = await repo.changes(_legalId);
    expect(history.single.action, GeofenceChangeAction.deactivated);
    expect(history.single.reason, 'Cerró el CAI');
    await expectLater(
      repo.setLegalActive(_legalId, active: false, reason: 'x'),
      throwsA(_apiError('La zona legal ya está desactivada.', 409)),
    );
  });

  test('una operativa no tiene historial de zona legal', () async {
    await expectLater(
      _repo().changes(_operationalId),
      throwsA(_apiError('La zona legal no existe.', 404)),
    );
  });
}
