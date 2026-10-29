import 'package:flutter/material.dart';

import '../../../data/order_models.dart';
import '../plan_schedule/schedule_values.dart';

/// Los campos de un pedido a otra central.
enum HubRequestInput { origin, offer, quantity }

/// Lo que comparten la urgencia y el abastecimiento a otra central: de
/// dónde sale, qué insumo y cuánto. El abastecimiento suma el calendario
/// ([schedule], RU-30). No pinta nada: guarda, valida y arma el body.
class HubRequestValues {
  final quantity = TextEditingController(text: '1');
  String? originHubId;
  CatalogOffer? offer;
  final schedule = ScheduleDraft();

  void dispose() {
    quantity.dispose();
    schedule.dispose();
  }

  /// Otra central de origen: el catálogo cambia, así que el insumo elegido
  /// ya no vale.
  void selectOrigin(String id) {
    if (id == originHubId) return;
    originHubId = id;
    offer = null;
  }

  int? get _qty => int.tryParse(quantity.text.trim());

  /// Un mensaje por campo con error; vacío si todo está bien. La cantidad
  /// no puede pasar del stock de la central de origen (Nest respondería
  /// 409) ni de 100000 (el máximo del DTO).
  Map<HubRequestInput, String> validate({required bool plan}) {
    final stock = offer?.availableQuantity ?? 100000;
    final max = stock < 100000 ? stock : 100000;
    final qty = _qty;
    final errors = <HubRequestInput, String?>{
      HubRequestInput.origin: originHubId == null
          ? 'Elige la central de origen.'
          : null,
      HubRequestInput.offer: originHubId != null && offer == null
          ? 'Elige el medicamento.'
          : null,
      HubRequestInput.quantity: qty == null || qty < 1 || qty > max
          ? 'La cantidad debe ser un entero entre 1 y $max.'
          : null,
    };
    return {
      for (final entry in errors.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  CreateHubEmergencyRequest emergency() => CreateHubEmergencyRequest(
    originHubId: originHubId!,
    medicationName: offer!.name,
    saleType: offer!.saleType,
    quantity: _qty!,
  );

  CreateHubPlanRequest plan() => CreateHubPlanRequest(
    originHubId: originHubId!,
    medicationName: offer!.name,
    saleType: offer!.saleType,
    quantity: _qty!,
    schedule: schedule.toSchedule(),
  );
}
