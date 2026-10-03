import 'package:flutter/material.dart';

import '../../data/fleet_models.dart';

/// Los campos del alta de dron en un solo objeto.
///
/// No pinta nada: conserva el controlador, lo libera y arma el body de
/// `POST /fleet/drones`. El modelo no es un campo de texto sino el `id`
/// elegido en el dropdown de `GET /fleet/models`.
class DroneFormValues {
  final identifier = TextEditingController();

  /// `id` del modelo elegido. Llega del dropdown, no del teclado.
  String? droneModelId;

  bool get hasModel => droneModelId != null && droneModelId!.isNotEmpty;

  void dispose() => identifier.dispose();

  /// Body de `POST /fleet/drones`. La central no la escribe el usuario:
  /// sale de la central que el operador tenía elegida.
  CreateDroneRequest request(String hubId) {
    return CreateDroneRequest(
      identifier: identifier.text.trim(),
      droneModelId: droneModelId!,
      hubId: hubId,
    );
  }

  /// Modelo elegido, para pintar sus especificaciones al lado del campo.
  DroneModel? model(List<DroneModel> models) {
    for (final model in models) {
      if (model.id == droneModelId) return model;
    }
    return null;
  }
}
