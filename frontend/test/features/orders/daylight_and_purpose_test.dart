import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/auth/token_store.dart';
import 'package:frontend/core/widgets/warning_banner.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/data/privacy_models.dart';
import 'package:frontend/features/auth/presentation/prescription_access_screen.dart';
import 'package:frontend/features/home/presentation/widgets/requester/daylight_note.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/remote_order_repository.dart';
import 'package:frontend/theme/app_theme.dart';

class _Store extends TokenStore {
  _Store() : super();

  @override
  Future<String?> read() async => null;
}

/// Anota cada ruta que se pide.
class _Api extends ApiClient {
  _Api() : super(tokenStore: _Store());

  final calls = <String>[];

  @override
  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    calls.add(path);
    return {
      'files': [
        {'index': 0, 'mime': 'image/jpeg', 'filename': 'formula-1.jpg'},
      ],
    };
  }

  @override
  Future<ApiBytes> getBytes(String path) async {
    calls.add(path);
    return ApiBytes(bytes: Uint8List(2), mime: 'image/jpeg');
  }
}

Daylight _day({required bool daylight}) => Daylight.fromJson({
  'date': '2026-11-15',
  'sunrise': '2026-11-15T10:58:00.000Z',
  'sunset': '2026-11-15T22:32:00.000Z',
  'now': '2026-11-15T15:00:00.000Z',
  'daylight': daylight,
});

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  ),
);

void main() {
  test('las franjas van de las 07:00 a las 16:00 (RF-44)', () {
    expect(slotTimes.first, '07:00');
    expect(slotTimes.last, '16:00');
    expect(slotTimes, hasLength(10));
  });

  test('la fórmula se abre con su propósito y sin él no lo manda', () async {
    final api = _Api();
    final repository = RemoteOrderRepository(apiClient: api);

    await repository.prescriptionFiles(
      'o1',
      purpose: PrescriptionPurpose.history,
    );
    await repository.prescriptionFiles('o1');

    expect(api.calls, [
      // La lista de hojas no registra un acceso: va sin propósito.
      '/orders/o1/prescription/files',
      '/orders/o1/prescription/0?purpose=history',
      '/orders/o1/prescription/files',
      '/orders/o1/prescription/0',
    ]);
  });

  testWidgets('de día dice las horas de vuelo, en hora de Colombia', (
    tester,
  ) async {
    await _pump(tester, DaylightNote(day: _day(daylight: true)));

    // 10:58 y 22:32 UTC son las 5:58 y las 17:32 en Colombia.
    final text = daylightHours(_day(daylight: true));
    expect(text, startsWith('Hoy se vuela de 5:58'));
    expect(text, contains('5:32'));
    expect(find.text(text), findsOneWidget);
    expect(find.byType(WarningBanner), findsNothing);
  });

  testWidgets('de noche avisa que la urgencia va por tierra', (tester) async {
    await _pump(tester, DaylightNote(day: _day(daylight: false)));

    expect(find.byType(WarningBanner), findsOneWidget);
    expect(find.textContaining('alternativa terrestre'), findsOneWidget);
  });

  test('el registro de accesos dice la hoja, el propósito y el rol', () {
    final access = PrescriptionAccess.fromJson({
      'id': 'a1',
      'orderId': '1a2b3c4d-0000-4000-8000-000000000000',
      'userId': 'u1',
      'userName': 'María Orozco',
      'role': 'dispatcher',
      'purpose': 'authorize',
      'fileIndex': 1,
      'accessedAt': '2026-11-15T15:00:00.000Z',
    });

    expect(access.role, UserRole.dispatcher);
    expect(access.shortOrderId, '1a2b3c4d');
    expect(accessFacts(access), 'Hoja 2 · Autorizar · Despachador');
    // Un propósito o un rol que la app no conozca no tumba la lista.
    final odd = PrescriptionAccess.fromJson({
      'orderId': 'o1',
      'role': 'auditor',
      'purpose': 'audit',
    });
    expect(odd.role, isNull);
    expect(odd.purposeLabel, 'Sin propósito');
  });
}
