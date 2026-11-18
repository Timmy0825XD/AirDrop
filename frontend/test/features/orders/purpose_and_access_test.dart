import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/auth/token_store.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/data/privacy_models.dart';
import 'package:frontend/features/auth/presentation/prescription_access_screen.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/remote_order_repository.dart';

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

void main() {
  test('las franjas van de las 07:00 a las 16:00 (RU-30)', () {
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
