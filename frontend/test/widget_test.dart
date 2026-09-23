import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/app/airdrop_app.dart';

void main() {
  testWidgets('La app arranca en la ruta de login',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AirDropApp()));
    await tester.pump();

    // AppBar de /login (placeholder de la Fase 1).
    expect(find.text('Ingresar'), findsOneWidget);
    // El placeholder indica que la pantalla real llega después.
    expect(find.textContaining('Fase 2'), findsOneWidget);
  });
}
