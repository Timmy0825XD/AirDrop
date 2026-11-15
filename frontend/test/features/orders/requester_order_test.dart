import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/prescription_attachment.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_order/prescription_picker.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_order/requester_order_values.dart';
import 'package:latlong2/latlong.dart';

const _ana = PublicUser(
  id: 'u-1',
  fullName: 'Ana Pérez',
  email: 'ana@correo.co',
  phone: '3001234567',
  role: UserRole.requester,
  status: UserStatus.active,
  hubIds: [],
  documentType: DocumentType.citizenshipId,
  documentNumber: '1065123456',
);

const _rx = CatalogOffer(
  name: 'Amoxicilina 500 mg',
  saleType: SaleType.prescription,
  requiresColdChain: false,
);

/// Un tamizaje completo (RF-41): sin alarma, adulto, fiebre de hoy.
void _fillTriage(RequesterOrderValues values) {
  values.triage
    ..noRedFlags()
    ..pickGroup(PatientGroup.olderAdult)
    ..symptoms.add(Symptom.fever)
    ..onset = SymptomOnset.today
    ..severity = SymptomSeverity.mild
    ..hasAllergies = false;
}

const _badillo = DeliveryPoint(
  id: 'd1111111-1111-4111-8111-111111111111',
  name: 'Puesto de salud de Badillo',
  municipality: 'Valledupar',
  location: LatLng(10.6314, -73.1279),
);

void main() {
  test('sin punto de entrega no deja enviar (RF-45)', () {
    final values = RequesterOrderValues()
      ..offer = _rx
      ..prescriptions = [
        PrescriptionAttachment(
          bytes: Uint8List.fromList([1, 2, 3]),
          mime: 'image/png',
          name: 'formula.png',
        ),
      ];
    addTearDown(values.dispose);
    values.description.text = 'Infección';

    expect(values.validate(plan: false), {
      RequesterInput.location: 'Elige un punto de entrega.',
    });
  });

  test('el GPS es opcional: sin él solo viaja el punto (RU-02)', () {
    final values = RequesterOrderValues()
      ..offer = const CatalogOffer(
        name: 'Acetaminofén 500 mg',
        saleType: SaleType.overTheCounter,
        requiresColdChain: false,
      )
      ..point = _badillo;
    addTearDown(values.dispose);
    values.description.text = 'Fiebre';
    _fillTriage(values);

    expect(values.validate(plan: false), isEmpty);
    final body = values.emergency(_ana).toJson();
    expect(body['deliveryPointId'], _badillo.id);
    expect(body.containsKey('requesterLocation'), isFalse);
    expect(body.containsKey('address'), isFalse);
    expect(body.containsKey('latitude'), isFalse);
  });

  test('bajo fórmula pide la imagen', () {
    final values = RequesterOrderValues()
      ..offer = _rx
      ..point = _badillo;
    addTearDown(values.dispose);
    values.description.text = 'Infección';

    expect(
      values.validate(plan: false)[RequesterInput.prescription],
      'La venta bajo fórmula exige la fórmula: un PDF o de 1 a 3 fotos.',
    );
  });

  test('la urgencia lleva el punto, el GPS redondeado y el documento', () {
    final values = RequesterOrderValues()
      ..offer = _rx
      ..point = _badillo
      ..location = const LatLng(10.4631234567, -73.2532987654)
      ..prescriptions = [
        PrescriptionAttachment(
          bytes: Uint8List.fromList([1, 2, 3]),
          mime: 'image/png',
          name: 'formula.png',
        ),
      ];
    addTearDown(values.dispose);
    values.description.text = ' Infección ';
    _fillTriage(values);

    final body = values.emergency(_ana);

    expect(body.deliveryPointId, _badillo.id);
    expect(body.toJson()['requesterLocation'], {
      'latitude': 10.463123,
      'longitude': -73.253299,
    });
    expect(body.description, 'Infección');
    expect(body.patientDocumentType, DocumentType.citizenshipId);
    expect(body.patientDocumentNumber, '1065123456');
    expect(body.toJson()['prescriptions'], [
      {'mime': 'image/png', 'base64': 'AQID'},
    ]);
    expect(body.toJson().containsKey('prescriptionImageBase64'), isFalse);
  });

  test('la entrega periódica valida la cantidad y manda el calendario', () {
    final values = RequesterOrderValues()
      ..offer = const CatalogOffer(
        name: 'Suero oral',
        saleType: SaleType.overTheCounter,
        requiresColdChain: false,
      )
      ..point = _badillo;
    values.schedule
      ..startDate = '2099-03-01'
      ..daysOfWeek.addAll({2, 4})
      ..time = '10:00';
    addTearDown(values.dispose);
    values.quantity.text = '0';

    expect(
      values.validate(plan: true)[RequesterInput.quantity],
      'La cantidad debe ser un entero entre 1 y 100000.',
    );

    values.quantity.text = '3';
    expect(values.validate(plan: true), isEmpty);
    final body = values.plan(_ana).toJson();
    expect(body['schedule'], {
      'kind': 'weekly',
      'startDate': '2099-03-01',
      'count': 4,
      'daysOfWeek': [2, 4],
      'everyWeeks': 1,
      'time': '10:00',
    });
    // Nunca los dos modos en el mismo body.
    expect(body.containsKey('frequency'), isFalse);
    expect(body.containsKey('startDate'), isFalse);
    expect(values.plan(_ana).prescriptions, isEmpty);
  });

  testWidgets('la fórmula muestra el documento con su nombre, no crudo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrescriptionPicker(
            user: _ana,
            files: const [],
            onTakePhoto: () {},
            onPickFiles: () {},
            onRemove: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.text('Paciente: Cédula de ciudadanía · 1065123456'),
      findsOneWidget,
    );
    expect(find.textContaining('citizenship_id'), findsNothing);
  });
}
