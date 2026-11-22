import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/corridor_art.dart';
import 'package:frontend/core/widgets/drone_glyph.dart';
import 'package:frontend/features/fleet/data/fleet_models.dart';
import 'package:frontend/features/fleet/presentation/widgets/drone_form/drone_form_header.dart';
import 'package:frontend/features/fleet/presentation/widgets/drone_form/drone_identifier_field.dart';
import 'package:frontend/features/fleet/presentation/widgets/drone_form/field_row_separator.dart';
import 'package:frontend/features/fleet/presentation/widgets/drone_model_field.dart';
import 'package:frontend/features/home/presentation/widgets/operator/operator_empty_card.dart';
import 'package:frontend/theme/app_icons.dart';
import 'package:frontend/theme/app_palette.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [AppPalette.light]),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la flecha comparte la fila del título y conserva Volver', (
    tester,
  ) async {
    var backs = 0;
    await _pump(
      tester,
      DroneFormHeader(hubName: 'Central La Paz', onBack: () => backs++),
    );
    final arrow = tester.getCenter(find.byIcon(AppIcons.back));
    final title = tester.getCenter(find.text('Nuevo dron'));
    expect((arrow.dy - title.dy).abs(), lessThan(16));
    await tester.tap(find.byTooltip('Volver'));
    expect(backs, 1);
  });

  testWidgets('Identificador es una fila editable con icono y separador', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      DroneIdentifierField(controller: controller, shakeCount: 0),
    );
    expect(find.byIcon(AppIcons.tag), findsOneWidget);
    expect(find.byType(FieldRowSeparator), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.border,
      InputBorder.none,
    );
    await tester.enterText(find.byType(TextField), 'GZ-05');
    expect(controller.text, 'GZ-05');
  });

  testWidgets('modelos ordenados, icono de marca y selección de Garza', (
    tester,
  ) async {
    const models = [
      DroneModel(
        id: 'c',
        code: 'cargo',
        name: 'Cóndor',
        maxSpeedKmh: 60,
        maxPayloadKg: 15,
        maxRangeKm: 30,
      ),
      DroneModel(
        id: 'g',
        code: 'balanced',
        name: 'Garza',
        maxSpeedKmh: 110,
        maxPayloadKg: 5,
        maxRangeKm: 90,
      ),
      DroneModel(
        id: 'r',
        code: 'rapid',
        name: 'Colibrí',
        maxSpeedKmh: 140,
        maxPayloadKg: 2,
        maxRangeKm: 120,
      ),
    ];
    String? selected;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (_, setState) => DroneModelField(
          models: models,
          selectedId: selected,
          onChanged: (id) => setState(() => selected = id),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Colibrí')).dy,
      lessThan(tester.getTopLeft(find.text('Garza')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Garza')).dy,
      lessThan(tester.getTopLeft(find.text('Cóndor')).dy),
    );
    expect(find.byType(FieldRowSeparator), findsNWidgets(3));
    expect(find.byType(DroneGlyph), findsNWidgets(3));
    await tester.tap(find.text('Garza'));
    await tester.pumpAndSettle();
    expect(selected, 'g');
    expect(find.byIcon(AppIcons.check), findsOneWidget);
  });

  testWidgets('ambos vacíos tienen corredor horizontal, sin mapa de fondo', (
    tester,
  ) async {
    await _pump(
      tester,
      const Column(
        children: [
          OperatorEmptyCard(
            title: 'Todo al día',
            message: 'No hay alertas ni revisiones pendientes.',
          ),
          SizedBox(height: 24),
          OperatorEmptyCard(
            title: 'Sin vuelos por ahora',
            message: 'Aquí verás los drones en misión.',
          ),
        ],
      ),
    );
    expect(find.byType(CorridorArt), findsNothing);
    expect(find.byType(DroneGlyph), findsNWidgets(2));
    expect(find.byIcon(AppIcons.home), findsNWidgets(2));
    expect(find.byIcon(AppIcons.destination), findsNWidgets(2));
    expect(
      tester.getCenter(find.byType(DroneGlyph).first).dy,
      lessThan(tester.getTopLeft(find.text('Todo al día')).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
