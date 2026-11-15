import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/corridor_art.dart';
import 'package:frontend/core/widgets/message_view.dart';
import 'package:frontend/core/widgets/skeleton.dart';
import 'package:frontend/theme/app_theme.dart';

Future<void> _pump(WidgetTester tester, Widget child, {double height = 800}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 360, height: height, child: child),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('el vacío lleva ilustración, título, mensaje y acción', (
    tester,
  ) async {
    var tapped = 0;
    await _pump(
      tester,
      MessageView(
        icon: Icons.receipt_long_rounded,
        title: 'Aún no tienes pedidos',
        message: 'Aquí verás su vuelo.',
        action: FilledButton(
          onPressed: () => tapped++,
          child: const Text('Pedir urgencia'),
        ),
      ),
    );

    final art = tester.widget<CorridorArt>(find.byType(CorridorArt));
    expect(art.scene, CorridorScene.empty);
    expect(find.text('Aún no tienes pedidos'), findsOneWidget);
    expect(find.text('Aquí verás su vuelo.'), findsOneWidget);
    await tester.tap(find.text('Pedir urgencia'));
    expect(tapped, 1);
  });

  testWidgets('el error pinta la ruta cortada y dice qué pasó', (tester) async {
    await _pump(tester, const MessageView.error(message: 'Sin conexión.'));

    final art = tester.widget<CorridorArt>(find.byType(CorridorArt));
    expect(art.scene, CorridorScene.broken);
    expect(find.text('No pudimos cargar esto'), findsOneWidget);
    expect(find.text('Sin conexión.'), findsOneWidget);
  });

  testWidgets('con poco alto se queda en el ícono, sin desbordar', (
    tester,
  ) async {
    await _pump(
      tester,
      const MessageView(
        icon: Icons.flight_land_rounded,
        message: 'No hay drones en misión ahora.',
      ),
      height: 180,
    );

    expect(find.byType(CorridorArt), findsNothing);
    expect(find.byIcon(Icons.flight_land_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el esqueleto anuncia la carga y cabe en una pantalla baja', (
    tester,
  ) async {
    await _pump(tester, const SkeletonList(), height: 200);

    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pump(tester, const SkeletonDetail(), height: 200);
    expect(tester.takeException(), isNull);
  });
}
