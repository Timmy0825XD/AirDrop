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
/// qué insumo, a qué punto de entrega (RU-02, RF-45) y, si es bajo
/// fórmula, la imagen. La urgencia suma la descripción; la entrega
/// periódica, la cantidad y el calendario ([schedule], RU-30).
///
/// El punto de entrega es **obligatorio**: el dron no llega a una casa. El
/// GPS es opcional y solo sirve para proponer el punto más cercano.
class RequesterOrderValues {
  final description = TextEditingController();
  final quantity = TextEditingController(text: '1');
  CatalogOffer? offer;

  /// Dónde baja el dron.
  DeliveryPoint? point;

  /// Dónde está el teléfono, si se usó "Usar mi ubicación".
  LatLng? location;

  /// La fórmula: un PDF o de 1 a 3 fotos (RU-25).
  List<PrescriptionAttachment> prescriptions = const [];
  final schedule = ScheduleDraft();

  /// RF-41 y RF-42: el tamizaje (solo la urgencia) y para quién es.
  final triage = TriageDraft();

  void dispose() {
    for (final c in [description, quantity]) {
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
      RequesterInput.location: point == null
          ? 'Elige un punto de entrega.'
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
      deliveryPointId: point!.id,
      requesterLocation: location,
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
      deliveryPointId: point!.id,
      requesterLocation: location,
      // Con una persona a cargo, la fórmula es de ella: el documento va
      // en `patient`, no el de la cuenta (§19.1).
      patientDocumentType: holderFormula ? user.documentType : null,
      patientDocumentNumber: holderFormula ? user.documentNumber : null,
      prescriptions: rx ? prescriptions : const [],
    );
  }
}
