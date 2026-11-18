import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/prescription_attachment.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/triage_card.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_order/patient_fields.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_order/requester_order_values.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_order/triage_fields.dart';
import 'package:frontend/features/orders/presentation/widgets/requester_order/triage_values.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:latlong2/latlong.dart';

PublicUser _holder({String? allergies}) => PublicUser(
  id: 'u-1',
  fullName: 'Valentina Rodríguez',
  email: 'v@correo.co',
  phone: '3001234567',
  role: UserRole.requester,
  status: UserStatus.active,
  hubIds: const [],
  documentType: DocumentType.citizenshipId,
  documentNumber: '1065432187',
  allergies: allergies,
);

void _child(TriageDraft draft) {
  draft
    ..forSomeoneElse = true
    ..patientDocumentType = PatientDocumentType.identityCard
    ..relation = PatientRelation.child;
  draft.patientName.text = 'Samuel Rodríguez Peña';
  draft.patientDocument.text = '1065123456';
}

void main() {
  group('TriageDraft (RF-41, RF-42)', () {
    test('sin contestar pide cada ficha', () {
      final draft = TriageDraft();
      addTearDown(draft.dispose);

      expect(draft.validateSituation().keys, {
        TriageInput.redFlags,
        TriageInput.group,
        TriageInput.symptoms,
        TriageInput.onset,
        TriageInput.severity,
      });
      expect(draft.validateAllergies().keys, {TriageInput.allergies});
    });

    test('"Ninguno" es una respuesta y quitar el último signo la borra', () {
      final draft = TriageDraft()..toggleRedFlag(RedFlag.seizure);
      addTearDown(draft.dispose);
      expect(draft.hasRedFlag, isTrue);

      draft.toggleRedFlag(RedFlag.seizure);
      expect(draft.anyRedFlag, isNull);

      draft.noRedFlags();
      expect(draft.anyRedFlag, isFalse);
      expect(
        draft.validateSituation().containsKey(TriageInput.redFlags),
        isFalse,
      );
    });

    test('pregunta por embarazo solo donde aplica', () {
      final draft = TriageDraft()..pickGroup(PatientGroup.adult);
      addTearDown(draft.dispose);
      expect(draft.validateSituation()[TriageInput.pregnant], isNotNull);

      draft
        ..pregnant = true
        ..pickGroup(PatientGroup.baby);
      expect(draft.pregnant, isNull);
      expect(draft.validateSituation()[TriageInput.pregnant], isNull);
    });

    test('la persona a cargo pide nombre, documento válido y parentesco', () {
      final draft = TriageDraft()..forSomeoneElse = true;
      addTearDown(draft.dispose);
      expect(draft.validateSituation(patientOnly: true).keys, {
        TriageInput.patientName,
        TriageInput.patientDocumentType,
        TriageInput.relation,
      });

      _child(draft);
      draft.patientDocument.text = '12345';
      expect(
        draft.validateSituation(patientOnly: true)[TriageInput.patientDocument],
        'El número no corresponde a ese documento.',
      );
      draft.patientDocument.text = '1065123456';
      expect(draft.validateSituation(patientOnly: true), isEmpty);
      expect(draft.toPatientOrNull()?.fullName, 'Samuel Rodríguez Peña');
    });

    test('trae las alergias de la cuenta una sola vez', () {
      final draft = TriageDraft();
      addTearDown(draft.dispose);
      draft.prefillFrom(_holder(allergies: 'Penicilina'));
      expect(draft.hasAllergies, isTrue);
      expect(draft.allergiesValue, 'Penicilina');

      draft
        ..hasAllergies = false
        ..prefillFrom(_holder(allergies: 'Penicilina'));
      expect(draft.allergiesValue, '');
    });
  });

  test('la urgencia para un hijo manda tamizaje y paciente, no el documento '
      'de la cuenta', () {
    final values = RequesterOrderValues()
      ..offer = const CatalogOffer(
        name: 'Amoxicilina 500 mg',
        saleType: SaleType.prescription,
        requiresColdChain: false,
      )
      ..location = const LatLng(10.47, -73.25)
      ..prescriptions = [
        PrescriptionAttachment(
          bytes: Uint8List.fromList([0xff, 0xd8, 0xff]),
          mime: 'image/jpeg',
          name: 'hoja.jpg',
        ),
      ];
    addTearDown(values.dispose);
    values.triage
      ..toggleRedFlag(RedFlag.breathingDifficulty)
      ..pickGroup(PatientGroup.child)
      ..pregnant = false
      ..symptoms.add(Symptom.fever)
      ..onset = SymptomOnset.hours
      ..severity = SymptomSeverity.severe
      ..hasAllergies = false;
    _child(values.triage);

    final json = values.emergency(_holder()).toJson();

    expect(json['triage'], {
      'redFlags': ['breathing_difficulty'],
      'patientGroup': 'child',
      'pregnant': false,
      'symptoms': ['fever'],
      'onset': 'hours',
      'severity': 'severe',
    });
    expect(json['patient'], {
      'fullName': 'Samuel Rodríguez Peña',
      'documentType': 'identity_card',
      'documentNumber': '1065123456',
      'relation': 'child',
    });
    expect(json['allergies'], '');
    expect(json['patientDocumentType'], isNull);
    expect(json['patientDocumentNumber'], isNull);
    // Sin nota, la descripción no viaja.
    expect(json.containsKey('description'), isFalse);
  });

  test('lee el tamizaje y el paciente como los manda Nest (§19.1)', () {
    final triage = OrderTriage.fromJson({
      'redFlags': ['seizure', 'desconocido'],
      'patientGroup': 'older_adult',
      'pregnant': null,
      'symptoms': ['pain'],
      'onset': 'days',
      'severity': 'mild',
    })!;
    expect(triage.redFlags, [RedFlag.seizure]);
    expect(triage.patientGroup, PatientGroup.olderAdult);
    expect(OrderTriage.fromJson(null), isNull);
    expect(
      OrderPatient.fromJson({
        'fullName': 'Samuel',
        'documentType': 'civil_registry',
        'documentNumber': '1065987654',
        'relation': 'child',
      })?.documentType,
      PatientDocumentType.civilRegistry,
    );
  });

  group('widgets', () {
    Future<void> host(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );
    }

    testWidgets('un signo de alarma muestra el 123', (tester) async {
      final draft = TriageDraft();
      addTearDown(draft.dispose);
      late StateSetter rebuild;
      await host(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return RedFlagsField(
              form: TriageForm(
                draft: draft,
                errors: const {},
                onChanged: () => rebuild(() {}),
              ),
            );
          },
        ),
      );

      expect(find.text('Llamar al 123'), findsNothing);
      await tester.tap(find.text('Convulsión'));
      await tester.pumpAndSettle();
      expect(find.text('Llamar al 123'), findsOneWidget);
      await tester.tap(find.text('Ninguno'));
      await tester.pumpAndSettle();
      expect(find.text('Llamar al 123'), findsNothing);
    });

    testWidgets('"Otra persona" pide sus datos', (tester) async {
      final draft = TriageDraft();
      addTearDown(draft.dispose);
      late StateSetter rebuild;
      await host(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return ForWhomField(
              form: TriageForm(
                draft: draft,
                errors: const {},
                onChanged: () => rebuild(() {}),
              ),
            );
          },
        ),
      );

      expect(find.text('Nombre completo del paciente'), findsNothing);
      await tester.tap(find.text('Otra persona'));
      await tester.pumpAndSettle();
      expect(find.text('Nombre completo del paciente'), findsOneWidget);
      expect(find.text('Tarjeta de identidad'), findsOneWidget);
      expect(find.text('Hijo o hija'), findsOneWidget);
    });

    testWidgets('el despachador ve la alarma, el paciente y las alergias', (
      tester,
    ) async {
      final order = Order.fromJson({
        'id': 'o1',
        'missionType': 'emergency',
        'destinationKind': 'person',
        'status': 'received',
        'priority': 'high',
        'medicationName': 'Amoxicilina 500 mg',
        'saleType': 'prescription',
        'requiresColdChain': false,
        'quantity': 1,
        'createdByUserId': 'u-1',
        'address': 'Punto marcado en el mapa',
        'triage': {
          'redFlags': ['breathing_difficulty'],
          'patientGroup': 'child',
          'pregnant': null,
          'symptoms': ['fever', 'pain'],
          'onset': 'hours',
          'severity': 'severe',
        },
        'allergies': 'Penicilina',
        'patient': {
          'fullName': 'Samuel Rodríguez Peña',
          'documentType': 'identity_card',
          'documentNumber': '1065123456',
          'relation': 'child',
        },
      });
      expect(TriageCard.appliesTo(order), isTrue);
      await host(tester, TriageCard(order: order));

      expect(find.text('Signo de alarma: Le cuesta respirar.'), findsOneWidget);
      expect(find.textContaining('Samuel Rodríguez Peña'), findsOneWidget);
      expect(find.text('Fiebre, Dolor'), findsOneWidget);
      expect(find.text('Penicilina'), findsOneWidget);
    });
  });
}
