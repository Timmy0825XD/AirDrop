import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
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

void main() {
  test('sin el punto en el mapa no deja enviar: Nest no lo autorizaría', () {
    final values = RequesterOrderValues()
      ..offer = _rx
      ..prescription = Uint8List(4)
      ..prescriptionMime = 'image/png';
    addTearDown(values.dispose);
    values
      ..description.text = 'Infección'
      ..address.text = 'Calle 16 # 9-40';

    expect(values.validate(plan: false), {
      RequesterInput.location: 'Toca el mapa donde debe llegar el dron.',
    });
  });

  test('bajo fórmula pide la imagen', () {
    final values = RequesterOrderValues()
      ..offer = _rx
      ..location = const LatLng(10.46, -73.25);
    addTearDown(values.dispose);
    values
      ..description.text = 'Infección'
      ..address.text = 'Calle 16 # 9-40';

    expect(
      values.validate(plan: false)[RequesterInput.prescription],
      'La venta bajo fórmula exige la imagen de la fórmula.',
    );
  });

  test('la urgencia lleva el punto redondeado y el documento del titular', () {
    final values = RequesterOrderValues()
      ..offer = _rx
      ..location = const LatLng(10.4631234567, -73.2532987654)
      ..prescription = Uint8List.fromList([1, 2, 3])
      ..prescriptionMime = 'image/png';
    addTearDown(values.dispose);
    values
      ..description.text = ' Infección '
      ..address.text = 'Calle 16 # 9-40';

    final body = values.emergency(_ana);

    expect(body.latitude, 10.463123);
    expect(body.longitude, -73.253299);
    expect(body.description, 'Infección');
    expect(body.patientDocumentType, DocumentType.citizenshipId);
    expect(body.patientDocumentNumber, '1065123456');
  });

  test('la entrega periódica valida la cantidad y manda la fecha elegida', () {
    final values = RequesterOrderValues()
      ..offer = const CatalogOffer(
        name: 'Suero oral',
        saleType: SaleType.overTheCounter,
        requiresColdChain: false,
      )
      ..location = const LatLng(10.46, -73.25)
      ..startDate = '2099-03-01';
    addTearDown(values.dispose);
    values
      ..address.text = 'Calle 16 # 9-40'
      ..quantity.text = '0';

    expect(
      values.validate(plan: true)[RequesterInput.quantity],
      'La cantidad debe ser un entero entre 1 y 100000.',
    );

    values.quantity.text = '3';
    expect(values.validate(plan: true), isEmpty);
    expect(values.plan(_ana).startDate, '2099-03-01');
    expect(values.plan(_ana).prescriptionImageBase64, isNull);
  });

  testWidgets('la fórmula muestra el documento con su nombre, no crudo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrescriptionPicker(user: _ana, image: null, onPick: () {}),
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
