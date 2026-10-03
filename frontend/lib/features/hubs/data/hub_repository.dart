import 'hub_models.dart';

/// Contrato de la feature de centrales. Las cuatro operaciones que el
/// backend expone para admin y despachador.
///
/// [mine] es el único método que puede devolver `null` (404 de Nest cuando
/// la cuenta no tiene una central asignada); los demás relanzan para que la
/// UI muestre el mensaje que define el backend.
abstract class HubRepository {
  /// `GET /hubs/me` — central asignada del despachador.
  Future<Hub?> mine();

  /// `GET /hubs?status=` — lista del admin; el operador recibe las suyas.
  Future<List<Hub>> list({HubStatus? status});

  /// `POST /hubs` — alta del administrador. Nace `active`.
  Future<Hub> create(CreateHubRequest request);

  /// `PATCH /hubs/:id/suspension` — activa o suspende. Si la central ya
  /// está en ese estado, Nest responde 409 y el error se propaga.
  Future<Hub> setSuspension(String id, {required bool suspended});
}
