import 'fleet_models.dart';

/// Contrato de la feature de flota. Las cinco operaciones que
/// `FleetController` expone, reservadas al operador de flota.
///
/// Ningún método convierte un error en `null`: Nest define los mensajes
/// (`La central está suspendida.`, `El dron no existe.`, `No puedes cambiar
/// el estado de un dron en misión.`) y la UI los muestra tal cual, igual
/// que en el resto de las features.
abstract class FleetRepository {
  /// `GET /fleet/models` — modelos sembrados, ordenados por nombre en el
  /// backend. El alta elige uno y guarda su `id`.
  Future<List<DroneModel>> listModels();

  /// `GET /fleet/drones?hubId=` — drones de **una** central. El `hubId` es
  /// obligatorio: sin él Nest responde `400 La central no es válida.`
  Future<List<Drone>> listDrones(String hubId);

  /// `POST /fleet/drones` — alta. El dron nace `available` y el modelo debe
  /// existir (`404 El modelo de dron no existe.`).
  Future<Drone> create(CreateDroneRequest request);

  /// `PATCH /fleet/drones/:id/status` — cambiar estado. Nunca lleva
  /// `in_mission` y falla con `409` si el dron ya está en misión.
  Future<Drone> updateStatus(String id, UpdateDroneStatusRequest request);

  /// `POST /fleet/drones/:id/maintenance` — registrar mantenimiento con
  /// motivo y fecha obligatorios; el dron queda `out_of_service`.
  Future<Drone> registerMaintenance(
    String id,
    RegisterMaintenanceRequest request,
  );
}
