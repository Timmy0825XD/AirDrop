import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/app_sheet.dart';
import 'package:frontend/core/widgets/confirm_sheet.dart';
import 'package:frontend/core/widgets/form_bottom_sheet.dart';
import 'package:go_router/go_router.dart';

/// Arma lo mismo que `RoleShell`: un `ShellRoute` con la pantalla abajo y,
/// encima, una barra pegada al borde inferior. La pestaña abre [open].
Future<int Function()> _pumpShell(
  WidgetTester tester,
  void Function(BuildContext context) open,
) async {
  var barTaps = 0;
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/tab',
    routes: [
      ShellRoute(
        builder: (context, state, child) => Stack(
          children: [
            child,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 92,
              child: Material(
                child: InkWell(
                  onTap: () => barTaps++,
                  child: const Center(child: Text('Barra')),
                ),
              ),
            ),
          ],
        ),
        routes: [
          GoRoute(
            path: '/tab',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => open(context),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
  return () => barTaps;
}

void main() {
  testWidgets('la hoja de formulario queda encima de la barra y la bloquea', (
    tester,
  ) async {
    String? saved;
    final barTaps = await _pumpShell(tester, (context) async {
      saved = await showAppSheet<String>(
        context,
        builder: (sheet) => FormBottomSheet(
          title: 'Editar nombre completo',
          saveLabel: 'Guardar',
          onSave: () => Navigator.pop(sheet, 'listo'),
          children: const [TextField()],
        ),
      );
    });

    // Antes la barra tapaba el botón y el toque caía en ella.
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(saved, 'listo');
    expect(barTaps(), 0);
  });

  testWidgets('con la hoja abierta, tocar la barra no navega', (tester) async {
    final barTaps = await _pumpShell(tester, (context) {
      showConfirmSheet(
        context,
        title: '¿Eliminar ítem?',
        message: 'Sale del inventario de la central.',
        confirmLabel: 'Eliminar',
        subject: const Text('Acetaminofén 500 mg'),
        icon: Icons.delete_outline_rounded,
      );
    });

    // La hoja y su velo cubren la barra: el toque no le llega.
    await tester.tap(find.text('Barra'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(barTaps(), 0);
  });

  testWidgets('la confirmación se puede tocar desde una pestaña', (
    tester,
  ) async {
    bool? confirmed;
    final barTaps = await _pumpShell(tester, (context) async {
      confirmed = await showConfirmSheet(
        context,
        title: '¿Eliminar ítem?',
        message: 'Sale del inventario de la central.',
        confirmLabel: 'Eliminar',
        subject: const Text('Acetaminofén 500 mg'),
        icon: Icons.delete_outline_rounded,
      );
    });

    await tester.tap(find.text('Barra'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(barTaps(), 0);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });
}
