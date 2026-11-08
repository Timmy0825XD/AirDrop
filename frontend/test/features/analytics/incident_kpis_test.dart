import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/analytics/data/analytics_models.dart';
import 'package:frontend/features/analytics/presentation/widgets/kpi_card.dart';
import 'package:frontend/theme/app_theme.dart';

/// El grupo "Fallas" como lo arma `analytics.rules.ts` desde §17: la tasa de
/// incidentes por cada 100 misiones y los drones que no volvieron.
final _failures = <String, dynamic>{
  'key': 'failures',
  'label': 'Fallas',
  'kpis': [
    {
      'key': 'incidentRate',
      'label': 'Incidentes en vuelo por cada 100 misiones',
      'unit': 'por 100',
      'value': 3.5,
      'previous': 2,
      'delta': 1.5,
      'status': 'amber',
      'target': {'kind': 'max', 'green': 2, 'amber': 5},
    },
    {
      'key': 'groundings',
      'label': 'Aterrizajes de emergencia y drones perdidos',
      'unit': 'drones',
      'value': 0,
      'status': 'green',
      'target': {'kind': 'max', 'green': 0, 'amber': 1},
    },
    {
      // Sin misiones que despegaran, Nest manda `null`: "Sin datos".
      'key': 'incidentRate',
      'label': 'Incidentes (otro periodo)',
      'unit': 'por 100',
      'value': null,
      'status': 'none',
    },
  ],
};

void main() {
  test('la tasa y los drones que no volvieron se leen con su meta', () {
    final group = KpiGroup.fromJson(_failures);
    final rate = group.kpis.first;
    expect(rate.status, KpiStatus.amber);
    expect(formatKpiValue(rate.value, rate.unit), '3,5 por 100');
    expect(kpiTargetLabel(rate.target, rate.unit), 'Meta: 2 por 100 o menos');
    expect(formatKpiValue(group.kpis.last.value, 'por 100'), 'Sin datos');
  });

  testWidgets('la tarjeta "Fallas" los muestra con su semáforo en 360 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: KpiGroupCard(group: KpiGroup.fromJson(_failures)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Incidentes en vuelo por cada 100 misiones'),
      findsOneWidget,
    );
    expect(find.text('3,5 por 100'), findsOneWidget);
    expect(find.text('Atención'), findsOneWidget);
    expect(
      find.text('Aterrizajes de emergencia y drones perdidos'),
      findsOneWidget,
    );
    expect(find.text('En meta'), findsOneWidget);
  });
}
