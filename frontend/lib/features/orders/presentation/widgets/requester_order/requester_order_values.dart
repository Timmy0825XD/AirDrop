import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../auth/data/auth_models.dart';
import '../../../../inventory/data/inventory_models.dart' show SaleType;
import '../../../data/order_models.dart';
import '../../order_format.dart';

/// Los campos de un pedido del solicitante que pueden tener error.
enum RequesterInput {
  offer,
  description,
  quantity,
  address,
  location,
  prescription,
  startDate,
}

/// Lo que comparten la urgencia y la entrega periódica del solicitante:
/// qué insumo, a dónde (dirección y punto en el mapa) y, si es bajo
/// fórmula, la imagen. La urgencia suma la descripción; la entrega
/// periódica, la cantidad, la frecuencia y la fecha de inicio.
///
/// La ubicación es **obligatoria**: sin coordenadas Nest no deja autorizar
/// el pedido (`MISSING_DESTINATION`), así que el despachador nunca podría
/// sacarlo.
class RequesterOrderValues {
  final description = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final address = TextEditingController();
  CatalogOffer? offer;
  LatLng? location;
  Uint8List? prescription;
  String? prescriptionMime;
  PlanFrequency frequency = PlanFrequency.weekly;
  String startDate = todayIso();

  void dispose() {
    for (final c in [description, quantity, address]) {
      c.dispose();
    }
  }

  bool get needsPrescription => offer?.saleType == SaleType.prescription;

  /// Un mensaje por campo con error; vacío si todo está bien.
  Map<RequesterInput, String> validate({required bool plan}) {
    final text = description.text.trim();
    final place = address.text.trim();
    final qty = int.tryParse(quantity.text.trim());
    final errors = <RequesterInput, String?>{
      RequesterInput.offer: offer == null
          ? 'Elige un medicamento del catálogo.'
          : null,
      RequesterInput.description: !plan && text.isEmpty
          ? 'Cuéntale al despachador para qué lo necesitas.'
          : null,
      RequesterInput.quantity: plan && (qty == null || qty < 1 || qty > 100000)
          ? 'La cantidad debe ser un entero entre 1 y 100000.'
          : null,
      RequesterInput.address: place.isEmpty
          ? 'La dirección es obligatoria.'
          : null,
      RequesterInput.location: location == null
          ? 'Toca el mapa donde debe llegar el dron.'
          : null,
      RequesterInput.prescription: needsPrescription && prescription == null
          ? 'La venta bajo fórmula exige la imagen de la fórmula.'
          : null,
      RequesterInput.startDate: plan && startDate.compareTo(todayIso()) < 0
          ? 'La fecha de inicio no puede ser anterior a hoy.'
          : null,
    };
    return {
      for (final entry in errors.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  double _round(double value) => double.parse(value.toStringAsFixed(6));

  /// El paciente de la fórmula es el titular de la cuenta.
  CreateEmergencyRequest emergency(PublicUser user) {
    final rx = needsPrescription;
    return CreateEmergencyRequest(
      medicationName: offer!.name,
      saleType: offer!.saleType,
      description: description.text.trim(),
      address: address.text.trim(),
      latitude: _round(location!.latitude),
      longitude: _round(location!.longitude),
      patientDocumentType: rx ? user.documentType : null,
      patientDocumentNumber: rx ? user.documentNumber : null,
      prescriptionMime: rx ? prescriptionMime : null,
      prescriptionImageBase64: rx ? base64Encode(prescription!) : null,
    );
  }

  CreatePlanRequest plan(PublicUser user) {
    final rx = needsPrescription;
    return CreatePlanRequest(
      medicationName: offer!.name,
      saleType: offer!.saleType,
      quantity: int.parse(quantity.text.trim()),
      frequency: frequency,
      startDate: startDate,
      address: address.text.trim(),
      latitude: _round(location!.latitude),
      longitude: _round(location!.longitude),
      patientDocumentType: rx ? user.documentType : null,
      patientDocumentNumber: rx ? user.documentNumber : null,
      prescriptionMime: rx ? prescriptionMime : null,
      prescriptionImageBase64: rx ? base64Encode(prescription!) : null,
    );
  }
}
