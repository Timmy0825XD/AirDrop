import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/prescription_attachment.dart';

void main() {
  test('Order.fromJson deja fechas String, droneId null y lee cola', () {
    final order = Order.fromJson({
      'id': 'a1111111-1111-4111-8111-111111111111',
      'missionType': 'emergency',
      'destinationKind': 'person',
      'status': 'received',
      'priority': 'high',
      'medicationName': 'Acetaminofén',
      'saleType': 'over_the_counter',
      'requiresColdChain': false,
      'quantity': 1,
      'description': null,
      'requesterId': 'r1',
      'createdByUserId': 'u1',
      'destinationHubId': null,
      'originHubId': null,
      'address': 'Calle 16',
      'latitude': 10.46314,
      'longitude': -73.25322,
      'droneId': null,
      'statusReason': null,
      'planId': null,
      'scheduledFor': null,
      'hasPrescription': false,
      'createdAt': '2026-10-04T16:40:00.000Z',
    });

    expect(order.scheduledFor, isNull);
    expect(order.droneId, isNull);
    expect(order.latitude, 10.46314);
    expect(order.createdAt, isNotNull);

    final entry = QueueEntry.fromJson({
      ..._orderJson(),
      'availableQuantity': 8,
      'unattended': true,
    });
    expect(entry.unattended, isTrue);
    expect(entry.availableQuantity, 8);
  });

  test('CreateEmergencyRequest.toJson omite quantity y GPS vacío', () {
    final request = CreateEmergencyRequest(
      medicationName: 'Acetaminofén',
      saleType: SaleType.overTheCounter,
      description: 'Fiebre alta',
      address: 'Calle 16',
    );
    final json = request.toJson();
    expect(json.containsKey('quantity'), isFalse);
    expect(json.containsKey('latitude'), isFalse);
    expect(json['saleType'], 'over_the_counter');
    expect(json.containsKey('prescriptions'), isFalse);
  });

  test(
    'CreateEmergencyRequest.toJson con fórmula manda el documento y los archivos',
    () {
      final request = CreateEmergencyRequest(
        medicationName: 'Amoxicilina',
        saleType: SaleType.prescription,
        description: 'Infección',
        address: 'Calle 16',
        latitude: 10.46314,
        longitude: -73.25322,
        patientDocumentType: DocumentType.citizenshipId,
        patientDocumentNumber: '12345678',
        prescriptions: [
          PrescriptionAttachment(
            bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
            mime: 'application/pdf',
            name: 'formula.pdf',
          ),
        ],
      );
      final json = request.toJson();
      expect(json['latitude'], 10.46314);
      expect(json['patientDocumentType'], 'citizenship_id');
      expect(json['prescriptions'], [
        {'mime': 'application/pdf', 'base64': 'JVBERg=='},
      ]);
    },
  );
}

Map<String, dynamic> _orderJson() {
  return {
    'id': 'a1111111-1111-4111-8111-111111111111',
    'missionType': 'emergency',
    'destinationKind': 'person',
    'status': 'received',
    'priority': 'high',
    'medicationName': 'Acetaminofén',
    'saleType': 'over_the_counter',
    'requiresColdChain': false,
    'quantity': 1,
    'description': null,
    'requesterId': 'r1',
    'createdByUserId': 'u1',
    'destinationHubId': null,
    'originHubId': null,
    'address': 'Calle 16',
    'latitude': 10.46314,
    'longitude': -73.25322,
    'droneId': null,
    'statusReason': null,
    'planId': null,
    'scheduledFor': null,
    'hasPrescription': false,
    'createdAt': '2026-10-04T16:40:00.000Z',
  };
}
