import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/prefs/app_prefs.dart';
import 'package:frontend/core/widgets/app_tab_bar.dart';
import 'package:frontend/features/settings/data/app_settings.dart';
import 'package:frontend/features/settings/presentation/settings_scope.dart';
import 'package:frontend/features/settings/presentation/settings_screen.dart';
import 'package:frontend/theme/app_palette.dart';
import 'package:frontend/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

ProviderContainer _container(MemoryPrefsStore prefs) {
  final container = ProviderContainer(
    overrides: [prefsStoreProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

/// La app mínima con los ajustes puestos, como en `AirDropApp`.
Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  Widget home, {
  MemoryPrefsStore? prefs,
}) async {
  final container = _container(prefs ?? MemoryPrefsStore(available: true));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(settingsProvider);
          final themes = themesFor(settings);
          return MaterialApp(
            theme: themes.light,
            darkTheme: themes.dark,
            themeMode: settings.themeMode,
            builder: (context, child) => SettingsScope(child: child!),
            home: home,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('sin nada guardado, los ajustes arrancan en automático y normal', () {
    final settings = _container(MemoryPrefsStore()).read(settingsProvider);

    expect(settings.themeMode, ThemeMode.system);
    expect(settings.textSize, TextSize.normal);
    expect(settings.highContrast, isFalse);
    expect(settings.reduceMotion, isFalse);
    expect(settings.simpleMode, isFalse);
  });

  test('cada cambio queda guardado y se lee al volver a abrir', () {
    final prefs = MemoryPrefsStore(available: true);
    _container(prefs).read(settingsProvider.notifier)
      ..setThemeMode(ThemeMode.dark)
      ..setTextSize(TextSize.extraLarge)
      ..setHighContrast(true)
      ..setReduceMotion(true)
      ..setSimpleMode(true);

    // Otra sesión de la app sobre el mismo teléfono.
    final again = _container(prefs).read(settingsProvider);
    expect(again.themeMode, ThemeMode.dark);
    expect(again.textSize, TextSize.extraLarge);
    expect(again.highContrast, isTrue);
    expect(again.reduceMotion, isTrue);
    expect(again.simpleMode, isTrue);
  });

  test('un valor guardado que ya no existe no rompe: vuelve al inicial', () {
    final prefs = MemoryPrefsStore(values: {'settings_theme': 'sepia'});
    expect(
      _container(prefs).read(settingsProvider).themeMode,
      ThemeMode.system,
    );
  });

  test('alto contraste: texto secundario a 7:1 y bordes más fuertes', () {
    for (final (high, normal) in [
      (AppTheme.lightHighContrast, AppTheme.light),
      (AppTheme.darkHighContrast, AppTheme.dark),
    ]) {
      final c = high.colorScheme;
      final backdrop = high.extension<AppPalette>()!.backdrop.first;
      for (final ground in [c.surface, backdrop]) {
        expect(_contrast(c.onSurface, ground), greaterThanOrEqualTo(7));
        expect(_contrast(c.onSurfaceVariant, ground), greaterThanOrEqualTo(7));
        expect(
          _contrast(c.outline, ground),
          greaterThan(_contrast(normal.colorScheme.outline, ground)),
        );
      }
      // La marca no cambia.
      expect(c.primary, normal.colorScheme.primary);
    }
  });

  testWidgets('el tamaño del texto se suma al del teléfono', (tester) async {
    late TextScaler seen;
    final container = await _pumpApp(
      tester,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: SettingsScope(
          child: Builder(
            builder: (context) {
              seen = MediaQuery.textScalerOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(seen.scale(10), closeTo(15, 0.01));

    container.read(settingsProvider.notifier).setTextSize(TextSize.large);
    await tester.pump();
    expect(seen.scale(10), closeTo(15 * 1.15, 0.01));
  });

  testWidgets('reducir movimiento vale aunque el teléfono no lo pida', (
    tester,
  ) async {
    late bool still;
    final container = await _pumpApp(
      tester,
      Builder(
        builder: (context) {
          still = MediaQuery.disableAnimationsOf(context);
          return const SizedBox();
        },
      ),
    );
    expect(still, isFalse);

    container.read(settingsProvider.notifier).setReduceMotion(true);
    await tester.pump();
    expect(still, isTrue);
  });

  testWidgets('el modo sencillo sube los botones a 56 dp', (tester) async {
    final container = await _pumpApp(
      tester,
      Scaffold(
        body: Center(
          child: FilledButton(onPressed: () {}, child: const Text('Pedir')),
        ),
      ),
    );
    expect(tester.getSize(find.byType(FilledButton)).height, 48);

    container.read(settingsProvider.notifier).setSimpleMode(true);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(FilledButton)).height, 56);
  });

  testWidgets('el tema se mira en la vista previa y solo cambia al aplicar', (
    tester,
  ) async {
    final container = await _pumpApp(tester, const SettingsScreen());
    Brightness shown() =>
        Theme.of(tester.element(find.text('Ajustes'))).brightness;
    expect(shown(), Brightness.light);

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();
    // Solo cambió la elección: la app sigue igual y nada se guardó.
    expect(shown(), Brightness.light);
    expect(container.read(settingsProvider).themeMode, ThemeMode.system);

    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    expect(shown(), Brightness.dark);
    expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
  });

  testWidgets('sin ser solicitante no hay modo sencillo ni bienvenida', (
    tester,
  ) async {
    await _pumpApp(tester, const SettingsScreen());

    expect(find.text('Alto contraste'), findsOneWidget);
    expect(find.text('Reducir movimiento'), findsOneWidget);
    expect(find.text('Modo sencillo'), findsNothing);
    expect(find.text('Ver la bienvenida'), findsNothing);
  });

  testWidgets('los ajustes caben en 320 px con el texto muy grande', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final prefs = MemoryPrefsStore(
      available: true,
      values: {'settings_text_size': 'extraLarge'},
    );
    await _pumpApp(tester, const SettingsScreen(), prefs: prefs);

    expect(tester.takeException(), isNull);
  });

  testWidgets('la barra sin acción central muestra solo los destinos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: AppTabBar(
            destinations: const [
              NavDestination(icon: Icons.home_rounded, label: 'Inicio'),
              NavDestination(
                icon: Icons.receipt_long_rounded,
                label: 'Pedidos',
              ),
              NavDestination(icon: Icons.person_rounded, label: 'Perfil'),
            ],
            selected: 0,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Pedidos'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Urgencia'), findsNothing);
  });
}
