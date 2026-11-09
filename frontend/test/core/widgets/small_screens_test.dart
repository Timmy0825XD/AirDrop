import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/app_max_width.dart';
import 'package:frontend/core/widgets/floating_nav_bar.dart';
import 'package:frontend/core/widgets/sliding_segmented.dart';

Future<void> _pumpAt(WidgetTester tester, double width, Widget child) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump(const Duration(milliseconds: 600));
}

final _bar = Align(
  alignment: Alignment.bottomCenter,
  child: FloatingNavBar(
    destinations: const [
      NavDestination(icon: Icons.home_outlined, label: 'Inicio'),
      NavDestination(icon: Icons.receipt_long_outlined, label: 'Pedidos'),
      NavDestination(icon: Icons.event_repeat_outlined, label: 'Planes'),
      NavDestination(icon: Icons.person_outline, label: 'Perfil'),
    ],
    selected: 1,
    onSelect: (_) {},
    center: NavCenterAction(
      icon: Icons.bolt,
      label: 'Pedir urgencia',
      onPressed: () {},
    ),
  ),
);

void main() {
  testWidgets('bajo 360 px la barra solo rotula el destino abierto', (
    tester,
  ) async {
    await _pumpAt(tester, 320, _bar);
    expect(find.text('Pedidos'), findsOneWidget);
    expect(find.text('Inicio'), findsNothing);
    expect(find.text('Perfil'), findsNothing);
    // El lector de pantalla igual lee cada destino.
    expect(find.bySemanticsLabel('Inicio'), findsOneWidget);

    await _pumpAt(tester, 400, _bar);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('el segmentado se desliza si las opciones no caben', (
    tester,
  ) async {
    Widget filter() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SlidingSegmented<int?>(
        options: const [
          SegmentOption(null, 'Todos'),
          SegmentOption(1, 'Despachadores'),
          SegmentOption(2, 'Operadores'),
        ],
        selected: null,
        onChanged: (_) {},
      ),
    );

    await _pumpAt(tester, 320, filter());
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);

    // La fuente de las pruebas es más ancha que la real: hace falta más aire.
    await _pumpAt(tester, 900, filter());
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('en web o tableta el contenido no pasa de 600 px', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      1200,
      AppMaxWidth(
        child: Builder(
          builder: (context) => Text('${MediaQuery.sizeOf(context).width}'),
        ),
      ),
    );
    expect(find.text('600.0'), findsOneWidget);
  });
}
