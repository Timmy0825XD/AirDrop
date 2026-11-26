import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/features/fleet/data/fleet_flight.dart';
import 'package:frontend/features/fleet/data/fleet_models.dart';
import 'package:frontend/features/home/presentation/widgets/operator/operator_work_card.dart';
import 'operator_test_data.dart';

void main() {
  testWidgets('espera las lecturas antes de declarar Todo al día', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpOperatorPage(
      tester,
      operatorData(drones: const AsyncLoading(), flights: const AsyncLoading()),
    );
    expect(find.text('Todo al día', skipOffstage: false), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Cargando pendientes'), skipOffstage: false),
      findsOneWidget,
    );
    await pumpOperatorPage(tester, operatorData());
    expect(find.text('Todo al día', skipOffstage: false), findsOneWidget);
    expect(
      find.text('Sin vuelos por ahora', skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'un fallo conserva las revisiones conocidas y permite reintentar',
    (tester) async {
      var retried = 0;
      final drone = operatorDrone('03', hubId: 'h2', due: true);
      final failed = AsyncError<List<Drone>>(
        const ApiException('Sin conexión'),
        StackTrace.empty,
        // Simula una recarga fallida conservando el último dato conocido.
        // ignore: invalid_use_of_internal_member
      ).copyWithPrevious(AsyncData([drone]));
      await pumpOperatorPage(
        tester,
        operatorData(drones: failed),
        onRetry: () => retried++,
      );
      expect(find.text('Todo al día', skipOffstage: false), findsNothing);
      expect(find.text('Cóndor CD-03', skipOffstage: false), findsOneWidget);
      expect(find.text('Sin conexión', skipOffstage: false), findsOneWidget);
      await tester.ensureVisible(find.text('Reintentar', skipOffstage: false));
      await tester.tap(find.text('Reintentar', skipOffstage: false));
      expect(retried, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sin centrales explica la asignación y abre el perfil', (
    tester,
  ) async {
    final opened = <String>[];
    await pumpOperatorPage(
      tester,
      operatorData(hubs: const AsyncData([])),
      onOpen: opened.add,
    );
    expect(find.text('Todo al día', skipOffstage: false), findsNothing);
    expect(find.text('Tu flota', skipOffstage: false), findsNothing);
    await tester.tap(find.text('Ver mi perfil', skipOffstage: false));
    expect(opened, ['/profile']);
  });

  testWidgets(
    'un error de centrales no se presenta como una asignación vacía',
    (tester) async {
      var retried = false;
      await pumpOperatorPage(
        tester,
        operatorData(
          hubs: AsyncError(
            const ApiException('No fue posible consultar las centrales'),
            StackTrace.empty,
          ),
        ),
        onRetry: () => retried = true,
      );
      expect(
        find.text('No pudimos cargar tus centrales', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Ver mi perfil', skipOffstage: false), findsNothing);
      await tester.tap(find.text('Reintentar', skipOffstage: false));
      expect(retried, isTrue);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'alertas, revisiones y vuelos caben a 320 px con texto x$scale',
      (tester) async {
        final opened = <String>[];
        final reviewed = <Drone>[];
        await pumpOperatorPage(
          tester,
          operatorData(
            drones: AsyncData([
              operatorDrone('03', hubId: 'h2', due: true),
              operatorDrone('04', status: DroneStatus.grounded),
            ]),
            flights: AsyncData([
              operatorFlight('01', alert: true),
              operatorFlight('02', hubId: 'h2', returning: true),
            ]),
          ),
          scale: scale,
          size: const Size(320, 720),
          onOpen: opened.add,
          onDrone: reviewed.add,
        );
        expect(find.text('Todo al día', skipOffstage: false), findsNothing);
        expect(
          find.text('En espera de rescate', skipOffstage: false),
          findsOneWidget,
        );
        final review = find.descendant(
          of: find.widgetWithText(
            OperatorWorkCard,
            'Cóndor CD-03',
            skipOffstage: false,
          ),
          skipOffstage: false,
          matching: find.text('Ver dron', skipOffstage: false),
        );
        await tester.ensureVisible(review);
        await tester.pumpAndSettle();
        await tester.tap(review);
        expect(reviewed.single.hubId, 'h2');
        await tester.scrollUntilVisible(
          find.text('GZ-02'),
          200,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        final backFlight = find.descendant(
          of: find.widgetWithText(
            OperatorWorkCard,
            'GZ-02',
            skipOffstage: false,
          ),
          skipOffstage: false,
          matching: find.text('Ver vuelo', skipOffstage: false),
        );
        await tester.ensureVisible(backFlight);
        await tester.tap(backFlight);
        expect(opened.last, '/tracking/p02');
        await tester.scrollUntilVisible(
          find.text('Últimos 30 días'),
          200,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('tres vuelos muestran dos tarjetas y acceso al mapa completo', (
    tester,
  ) async {
    final opened = <String>[];
    await pumpOperatorPage(
      tester,
      operatorData(
        flights: AsyncData([
          operatorFlight('01'),
          operatorFlight('02'),
          operatorFlight('03'),
        ]),
      ),
      onOpen: opened.add,
    );
    expect(find.text('GZ-01', skipOffstage: false), findsOneWidget);
    expect(find.text('GZ-02', skipOffstage: false), findsOneWidget);
    expect(find.text('GZ-03', skipOffstage: false), findsNothing);
    final all = find.text('Ver los 3 vuelos en el mapa');
    await tester.scrollUntilVisible(all, 200);
    await tester.pumpAndSettle();
    await tester.tap(all);
    expect(opened, ['/fleet/flights']);
  });

  testWidgets(
    'un estado desconocido requiere revisión y no habilita pilotaje',
    (tester) async {
      await pumpOperatorPage(
        tester,
        operatorData(
          drones: AsyncData([operatorDrone('99', status: DroneStatus.unknown)]),
        ),
      );
      expect(find.text('Todo al día', skipOffstage: false), findsNothing);
      expect(
        find.text('Estado por confirmar', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.textContaining('Despegar'), findsNothing);
    },
  );

  testWidgets('un fallo de vuelos conserva las tarjetas y evita el vacío', (
    tester,
  ) async {
    final failed = AsyncError<List<FleetFlight>>(
      const ApiException('Sin red'),
      StackTrace.empty,
      // Simula una recarga fallida conservando el último dato conocido.
      // ignore: invalid_use_of_internal_member
    ).copyWithPrevious(AsyncData([operatorFlight('01')]));
    await pumpOperatorPage(tester, operatorData(flights: failed));
    expect(find.text('Todo al día', skipOffstage: false), findsNothing);
    expect(
      find.text('Sin vuelos por ahora', skipOffstage: false),
      findsNothing,
    );
    expect(find.text('GZ-01', skipOffstage: false), findsOneWidget);
    expect(find.text('Sin red', skipOffstage: false), findsOneWidget);
  });
}
