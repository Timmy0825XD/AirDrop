import 'inventory_models.dart';

/// Contrato de la feature de inventario. Las cuatro operaciones que
/// `InventoryController` expone, reservadas al despachador.
///
/// Ningún método convierte un error en `null`: `GET /inventory` responde
/// `La central está suspendida.` (403) cuando la central del despachador no
/// está activa y la UI muestra ese mensaje tal cual, igual que el resto de
/// las respuestas de Nest.
abstract class InventoryRepository {
  /// `GET /inventory` — ítems de la central asignada, ordenados por nombre
  /// y vencimiento en el backend.
  Future<List<InventoryItem>> list();

  /// `POST /inventory` — alta. La central no viaja en el body.
  Future<InventoryItem> create(CreateInventoryItemRequest request);

  /// `PATCH /inventory/:id` — edición. El cuerpo solo debe llevar los
  /// campos cambiados; vacío responde 400.
  Future<InventoryItem> update(String id, UpdateInventoryItemRequest request);

  /// `DELETE /inventory/:id` — `204` sin cuerpo que no se parsea.
  Future<void> remove(String id);
}
