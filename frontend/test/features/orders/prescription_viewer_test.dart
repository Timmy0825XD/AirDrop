import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/files/temp_file_share.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/data/remote_order_repository.dart';
import 'package:frontend/features/orders/presentation/prescription_viewer_screen.dart';
import 'package:frontend/theme/app_theme.dart';

import '../auth/presentation/auth_controller_test.dart' show FakeTokenStore;

/// Responde la lista de hojas y cada hoja, como Nest (§19.2).
class _Api extends ApiClient {
  _Api() : super(tokenStore: FakeTokenStore());

  final calls = <String>[];

  @override
  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    calls.add(path);
    return {
      'files': [
        {'index': 0, 'mime': 'image/jpeg', 'filename': 'formula-o1-1.jpg'},
        {'index': 1, 'mime': 'application/pdf', 'filename': 'formula-o1-2.pdf'},
      ],
    };
  }

  @override
  Future<ApiBytes> getBytes(String path) async {
    calls.add(path);
    return ApiBytes(bytes: Uint8List.fromList([1, 2]), mime: 'image/jpeg');
  }
}

/// "Abrir con…" de mentira: anota qué se abrió y si se borró.
class _Share extends TempFileShare {
  final opened = <String>[];
  var cleared = 0;

  @override
  Future<void> open({
    required Uint8List bytes,
    required String name,
    required String mime,
  }) async => opened.add('$name $mime');

  @override
  Future<void> clear() async => cleared++;
}

PrescriptionFile _photo(String name) =>
    PrescriptionFile(bytes: Uint8List(4), mime: 'image/jpeg', name: name);

void main() {
  test('el repositorio baja la lista y después cada hoja', () async {
    final api = _Api();
    final files = await RemoteOrderRepository(
      apiClient: api,
    ).prescriptionFiles('o1');

    expect(api.calls, [
      '/orders/o1/prescription/files',
      '/orders/o1/prescription/0',
      '/orders/o1/prescription/1',
    ]);
    expect(files.map((f) => f.name), ['formula-o1-1.jpg', 'formula-o1-2.pdf']);
    expect(files.last.isPdf, isTrue);
  });

  group('PrescriptionViewerScreen', () {
    Future<_Share> pump(
      WidgetTester tester,
      Future<List<PrescriptionFile>> Function() files,
    ) async {
      final share = _Share();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderPrescriptionProvider('o1').overrideWith((ref) => files()),
            tempFileShareProvider.overrideWithValue(share),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PrescriptionViewerScreen(orderId: 'o1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return share;
    }

    testWidgets('pasa de hoja y abre con otra app la que se ve', (
      tester,
    ) async {
      final share = await pump(
        tester,
        () async => [_photo('formula-o1-1.jpg'), _photo('formula-o1-2.jpg')],
      );

      expect(find.text('Hoja 1 de 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Hoja siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Hoja 2 de 2'), findsOneWidget);

      await tester.tap(find.byTooltip('Abrir con…'));
      await tester.pumpAndSettle();
      expect(share.opened, ['formula-o1-2.jpg image/jpeg']);

      // Al cerrar el visor se borra la copia temporal.
      await tester.pumpWidget(const SizedBox());
      expect(share.cleared, 1);
    });

    testWidgets('una foto dañada se explica y se puede girar', (tester) async {
      await pump(tester, () async => [_photo('formula-o1-1.jpg')]);

      expect(find.text('Una hoja'), findsOneWidget);
      expect(
        find.textContaining('No se pudo mostrar esta hoja'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Girar'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns,
        1,
      );
    });

    testWidgets('muestra qué revisar en una hoja aparte', (tester) async {
      await pump(tester, () async => [_photo('formula-o1-1.jpg')]);

      await tester.tap(find.byTooltip('Qué revisar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('En español y legible'), findsOneWidget);
    });

    testWidgets('si Nest no la deja ver, dice su mensaje', (tester) async {
      await pump(
        tester,
        () async => throw const ApiException('El pedido no existe.'),
      );

      expect(find.text('El pedido no existe.'), findsOneWidget);
      final open = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.open_in_new_rounded),
      );
      expect(open.onPressed, isNull);
    });
  });
}
