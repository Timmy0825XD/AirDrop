import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../auth/data/auth_models.dart';
import '../../../../inventory/data/inventory_models.dart' show SaleType;
import '../../../data/order_models.dart';
import '../../../data/prescription_attachment.dart';
import '../plan_schedule/schedule_values.dart';
import 'triage_values.dart';

/// Los campos de un pedido del solicitante que pueden tener error.
enum RequesterInput { offer, description, quantity, location, prescription }

/// Lo que comparten la urgencia y la entrega periódica del solicitante:
/// qué insumo, a dónde (el punto en el mapa y una referencia opcional,
/// RU-02) y, si es bajo fórmula, la imagen. La urgencia suma la descripción; la entrega
/// periódica, la cantidad y el calendario ([schedule], RU-30).
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

  /// El error del GPS si el punto salió de "Usar mi ubicación"; `null` si se
  /// marcó a mano.
  double? locationAccuracyM;

  /// La fórmula: un PDF o de 1 a 3 fotos (RU-25).
  List<PrescriptionAttachment> prescriptions = const [];
  final schedule = ScheduleDraft();

  /// RF-41 y RF-42: el tamizaje (solo la urgencia) y para quién es.
  final triage = TriageDraft();

  void dispose() {
    for (final c in [description, quantity, address]) {
      c.dispose();
    }
    schedule.dispose();
    triage.dispose();
  }

  bool get needsPrescription => offer?.saleType == SaleType.prescription;

  /// Un mensaje por campo con error; vacío si todo está bien.
  Map<RequesterInput, String> validate({required bool plan}) {
    final qty = int.tryParse(quantity.text.trim());
    final errors = <RequesterInput, String?>{
      RequesterInput.offer: offer == null
          ? 'Elige un medicamento del catálogo.'
          : null,
      RequesterInput.quantity: plan && (qty == null || qty < 1 || qty > 100000)
          ? 'La cantidad debe ser un entero entre 1 y 100000.'
          : null,
      RequesterInput.location: location == null
          ? 'Usa tu ubicación o toca el mapa donde debe llegar el dron.'
          : null,
      RequesterInput.prescription: needsPrescription && prescriptions.isEmpty
          ? 'La venta bajo fórmula exige la fórmula: un PDF o de 1 a 3 fotos.'
          : null,
    };
    return {
      for (final entry in errors.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  double _round(double value) => double.parse(value.toStringAsFixed(6));

  /// La referencia escrita, o `null` para que Nest ponga la de siempre.
  String? get reference {
    final text = address.text.trim();
    return text.isEmpty ? null : text;
  }

  /// El paciente de la fórmula es el titular de la cuenta.
  CreateEmergencyRequest emergency(PublicUser user) {
    final rx = needsPrescription;
    final holderFormula = rx && !triage.forSomeoneElse;
    return CreateEmergencyRequest(
      medicationName: offer!.name,
      saleType: offer!.saleType,
      description: description.text.trim(),
      triage: triage.toTriage(),
      patient: triage.toPatient(),
      allergies: triage.allergiesValue,
      address: reference,
      latitude: _round(location!.latitude),
      longitude: _round(location!.longitude),
      // Con una persona a cargo, la fórmula es de ella: el documento va
      // en `patient`, no el de la cuenta (§19.1).
      patientDocumentType: holderFormula ? user.documentType : null,
      patientDocumentNumber: holderFormula ? user.documentNumber : null,
      prescriptions: rx ? prescriptions : const [],
    );
  }

  CreatePlanRequest plan(PublicUser user) {
    final rx = needsPrescription;
    final holderFormula = rx && !triage.forSomeoneElse;
    return CreatePlanRequest(
      medicationName: offer!.name,
      saleType: offer!.saleType,
      quantity: int.parse(quantity.text.trim()),
      schedule: schedule.toSchedule(),
      prescriptionValidUntil: rx ? schedule.prescriptionValidUntil : null,
      patient: triage.toPatient(),
      address: reference,
      latitude: _round(location!.latitude),
      longitude: _round(location!.longitude),
      // Con una persona a cargo, la fórmula es de ella: el documento va
      // en `patient`, no el de la cuenta (§19.1).
      patientDocumentType: holderFormula ? user.documentType : null,
      patientDocumentNumber: holderFormula ? user.documentNumber : null,
      prescriptions: rx ? prescriptions : const [],
    );
  }
}
