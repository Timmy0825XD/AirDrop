import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/geofences/data/geofence_models.dart';
import 'package:frontend/features/geofences/presentation/geofence_draw_screen.dart';
import 'package:frontend/features/geofences/presentation/widgets/geometry_draft.dart';

/// Abre el modo dibujar desde un botón y guarda si se tocó "Listo".
Future<List<bool>> _pumpLauncher(
  WidgetTester tester,
  GeometryDraft draft,
) async {
  final results = <bool>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              results.add(await GeofenceDrawScreen.open(context, draft)),
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

bool _listoEnabled(WidgetTester tester) =>
    tester.widget<TextButton>(find.widgetWithText(TextButton, 'Listo')).enabled;

void main() {
  testWidgets('cada toque pone un vértice y Listo se prende con 3', (
    tester,
  ) async {
    final draft = GeometryDraft();
    final results = await _pumpLauncher(tester, draft);
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
    expect(results.single, isTrue);
    expect(draft.vertices, hasLength(3));
    expect(draft.vertices.first, hasLength(2), reason: '[lng, lat]');
  });

  testWidgets('deshacer, tocar un vértice y borrar todo los quitan', (
    tester,
  ) async {
    await _pumpLauncher(
      tester,
      GeometryDraft()
        ..vertices = [
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

  testWidgets('salir sin Listo no cambia la forma', (tester) async {
    final draft = GeometryDraft();
    final results = await _pumpLauncher(tester, draft);
    await _tapMap(tester, Offset.zero);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(results.single, isFalse);
    expect(draft.vertices, isEmpty);
  });

  testWidgets('en círculo, el toque pone el centro y Listo lo guarda', (
    tester,
  ) async {
    final draft = GeometryDraft()..shape = GeofenceShape.circle;
    await _pumpLauncher(tester, draft);
    expect(find.text('Toca el mapa para poner el centro.'), findsOne);
    expect(_listoEnabled(tester), isFalse);

    await _tapMap(tester, Offset.zero);
    expect(find.textContaining('Radio: 200 m'), findsOne);
    expect(find.byType(Slider), findsOne);

    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(draft.center, isNotNull);
    expect(draft.radiusM, 200);
  });
}
