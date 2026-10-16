import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/geofences/presentation/geofence_draw_screen.dart';

/// Abre el modo dibujar desde un botón y guarda lo que devuelve "Listo".
Future<List<List<List<double>>?>> _pumpLauncher(
  WidgetTester tester, {
  List<List<double>> initial = const [],
}) async {
  final results = <List<List<double>>?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              results.add(await GeofenceDrawScreen.open(context, initial)),
          child: const Text('abrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return results;
}

/// Un toque en el mapa, corrido desde el centro. Espera a que el mapa
/// descarte el doble toque antes de avisar el toque simple.
Future<void> _tapMap(WidgetTester tester, Offset shift) async {
  await tester.tapAt(tester.getCenter(find.byType(FlutterMap)) + shift);
  await tester.pump(const Duration(milliseconds: 400));
}

bool _listoEnabled(WidgetTester tester) => tester
    .widget<TextButton>(find.widgetWithText(TextButton, 'Listo'))
    .enabled;

void main() {
  testWidgets('cada toque pone un vértice y Listo se prende con 3', (
    tester,
  ) async {
    final results = await _pumpLauncher(tester);
    expect(find.text('Toca el mapa para poner el primer vértice.'), findsOne);
    expect(_listoEnabled(tester), isFalse);

    await _tapMap(tester, const Offset(-60, -40));
    await _tapMap(tester, const Offset(60, -40));
    expect(find.textContaining('2 de 3 vértices'), findsOne);
    expect(_listoEnabled(tester), isFalse);

    await _tapMap(tester, const Offset(0, 50));
    expect(find.textContaining('3 vértices. El polígono'), findsOne);
    expect(_listoEnabled(tester), isTrue);

    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(results.single, hasLength(3));
    expect(results.single!.first, hasLength(2), reason: '[lng, lat]');
  });

  testWidgets('deshacer, tocar un vértice y borrar todo los quitan', (
    tester,
  ) async {
    await _pumpLauncher(
      tester,
      initial: const [
        [-73.26, 10.46],
        [-73.24, 10.46],
        [-73.25, 10.48],
      ],
    );
    expect(find.textContaining('3 vértices'), findsOne);

    await tester.tap(find.text('Deshacer'));
    await tester.pump();
    expect(find.textContaining('2 de 3 vértices'), findsOne);

    // El número del vértice en el mapa.
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(find.textContaining('1 de 3 vértices'), findsOne);

    await tester.tap(find.text('Borrar todo'));
    await tester.pump();
    expect(find.text('Toca el mapa para poner el primer vértice.'), findsOne);
  });

  testWidgets('salir sin Listo no devuelve vértices', (tester) async {
    final results = await _pumpLauncher(tester);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(results.single, isNull);
  });
}
