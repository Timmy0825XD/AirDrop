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

  /// La urgencia elige primero el medicamento (del catálogo general) y
  /// después de qué central sale; `null` mientras no se elija.
  CatalogOffer? wanted;

  /// Otra central de origen: el catálogo cambia, así que el insumo elegido
  /// ya no vale.
  void selectOrigin(String id) {
    if (id == originHubId) return;
    originHubId = id;
    offer = null;
  }

  /// Otro medicamento (urgencia): la central elegida puede no tenerlo.
  void pickMedication(CatalogOffer medication) {
    wanted = medication;
    originHubId = null;
    offer = null;
  }

  /// La central de la que sale, con su oferta (y su stock) de ese insumo.
  void pickSource(String hubId, CatalogOffer hubOffer) {
    originHubId = hubId;
    offer = hubOffer;
  }

  int? get _qty => int.tryParse(quantity.text.trim());

  /// Un mensaje por campo con error; vacío si todo está bien. La cantidad
  /// no puede pasar del stock de la central de origen (Nest respondería
  /// 409) ni de 100000 (el máximo del DTO).
  ///
  /// Con [medicationFirst] (la urgencia) el orden es al revés: primero se
  /// pide el medicamento y solo después la central.
  Map<HubRequestInput, String> validate({
    required bool plan,
    bool medicationFirst = false,
  }) {
    final stock = offer?.availableQuantity ?? 100000;
    final max = stock < 100000 ? stock : 100000;
    final qty = _qty;
    final errors = <HubRequestInput, String?>{
      HubRequestInput.origin: medicationFirst
          ? (wanted != null && originHubId == null
                ? 'Elige de qué central sale.'
                : null)
          : (originHubId == null ? 'Elige la central de origen.' : null),
      HubRequestInput.offer: medicationFirst
          ? (wanted == null ? 'Elige el medicamento.' : null)
          : (originHubId != null && offer == null
                ? 'Elige el medicamento.'
                : null),
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
