import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/core/location/device_location.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/presentation/auth_controller.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/local_order_repository.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/presentation/plan_form_screen.dart';
import 'package:frontend/features/orders/presentation/widgets/periodic/periodic_calendar.dart';
import 'package:frontend/features/orders/presentation/widgets/periodic/periodic_layout.dart';
import 'package:frontend/features/orders/presentation/widgets/plan_schedule/schedule_fields.dart';
import 'package:frontend/features/orders/presentation/widgets/plan_schedule/schedule_preview_state.dart';
import 'package:frontend/features/orders/presentation/widgets/plan_schedule/schedule_values.dart';
import 'package:frontend/theme/app_palette.dart';

const _offer = CatalogOffer(
  name: 'Acetaminofén 500 mg',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
);
const _plan = DeliveryPlan(
  id: 'new-plan',
  status: PlanStatus.active,
  medicationName: 'Acetaminofén 500 mg',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
  quantity: 1,
  startDate: '2030-11-22',
  windowEndsOn: '2030-12-22',
  destinationKind: DestinationKind.person,
  address: 'Patio',
  hasPrescription: false,
  renewalDue: false,
);
PlanPreview _preview(String date) => PlanPreview(
  occurrences: [
    PreviewOccurrence(
      date: date,
      scheduledAt: DateTime.parse('${date}T15:00:00Z'),
      windowEndsAt: DateTime.parse('${date}T16:00:00Z'),
    ),
  ],
);

class _Auth extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.authenticated(
    PublicUser(
      id: 'requester',
      fullName: 'Ana Pérez',
      email: 'ana@correo.co',
      phone: '3001234567',
      role: UserRole.requester,
      status: UserStatus.active,
      hubIds: [],
    ),
  );
}

class _Gps extends DeviceLocation {
  @override
  Future<LocationFix> current() async =>
      const LocationFix(point: LatLng(10.5, -73.3), accuracyM: 5);
}

class _Repository extends LocalOrderRepository {
  CreatePlanRequest? saved;
  final responses = <Completer<PlanPreview>>[];
  int calls = 0;
  @override
  Future<PlanPreview> previewPlan(
    PlanSchedule schedule, {
    String? prescriptionValidUntil,
  }) {
    final index = calls++;
    return index < responses.length
        ? responses[index].future
        : Future.value(_preview('2030-11-22'));
  }

  @override
  Future<DeliveryPlan> createPlan(CreatePlanRequest request) async {
    saved = request;
    return _plan;
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Repository repo, {
  Widget? child,
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => child ?? const PlanFormScreen()),
      GoRoute(
        path: '/orders/plans/:id',
        builder: (_, _) => const Scaffold(body: Text('Plan creado')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Auth.new),
        catalogProvider.overrideWith((_) async => [_offer]),
        orderRepositoryProvider.overrideWithValue(repo),
        deviceLocationProvider.overrideWithValue(_Gps()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(extensions: const [AppPalette.light]),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    250,
    scrollable: find.byType(Scrollable).last,
    maxScrolls: 40,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _toCalendar(WidgetTester tester) async {
  await _tap(tester, 'Buscar medicamento');
  await _tap(tester, _offer.name);
  await _tap(tester, 'Elegir calendario');
}

Future<void> _chooseDays(WidgetTester tester) async {
  await _tap(tester, 'Días de entrega');
  await _tap(tester, 'Lunes');
  await _tap(tester, 'Miércoles');
  await _tap(tester, 'Confirmar selección (2)');
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

class _PreviewHarness extends ConsumerStatefulWidget {
  const _PreviewHarness();
  @override
  ConsumerState<_PreviewHarness> createState() => _PreviewHarnessState();
}

class _PreviewHarnessState extends ConsumerState<_PreviewHarness>
    with SchedulePreviewState {
  final draft = ScheduleDraft()..daysOfWeek.add(1);
  @override
  void initState() {
    super.initState();
    schedulePreview(draft, needsPrescription: false);
  }

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text(
          previewLoading
              ? 'Cargando fechas'
              : preview?.occurrences.first.date ?? 'Sin fechas',
        ),
        TextButton(
          onPressed: () {
            draft.time = '11:00';
            schedulePreview(draft, needsPrescription: false);
          },
          child: const Text('Cambiar'),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('recorre los pasos, conserva el calendario y crea el plan', (
    tester,
  ) async {
    final repo = _Repository();
    await _pump(tester, repo);
    await _tap(tester, 'Elegir calendario');
    expect(find.text('Elige un medicamento del catálogo.'), findsOneWidget);
    await _toCalendar(tester);
    await _chooseDays(tester);
    expect(find.text('1 entrega programada'), findsOneWidget);
    await _tap(tester, 'Elegir entrega');
    await _tap(tester, 'Programar entregas');
    expect(repo.saved, isNull);
    expect(find.textContaining('Usa tu ubicación'), findsOneWidget);
    await _tap(tester, 'Tu calendario');
    expect(find.text('Lunes, Miércoles'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await _tap(tester, 'Elegir entrega');
    await _tap(tester, 'Usar mi ubicación');
    await _tap(tester, 'Programar entregas');
    expect(repo.saved?.schedule?.daysOfWeek, [1, 3]);
    expect(repo.saved?.quantity, 1);
    expect(find.text('Plan creado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'permite días del mes y fechas sueltas sin cambiar las opciones del negocio',
    (tester) async {
      await _pump(tester, _Repository());
      await _toCalendar(tester);
      await _tap(tester, '¿Cómo se repite?');
      await _tap(tester, 'Un día del mes');
      await _tap(tester, 'Confirmar selección');
      await _tap(tester, 'Día del mes');
      await _tap(tester, '31');
      expect(find.text('El día 31 de cada mes'), findsOneWidget);
      await _tap(tester, '¿Cómo se repite?');
      await _tap(tester, 'Fechas sueltas');
      await _tap(tester, 'Confirmar selección');
      expect(find.text('Tus fechas (0/30)'), findsOneWidget);
      expect(find.text('Fecha de inicio'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('el calendario cabe en móvil con texto al 200 %', (tester) async {
    final draft = ScheduleDraft()..daysOfWeek.addAll([1, 3, 5]);
    addTearDown(draft.dispose);
    await _pump(
      tester,
      _Repository(),
      scale: 2,
      child: PeriodicLayout(
        step: 1,
        onBack: () {},
        body: PeriodicCalendar(
          form: ScheduleForm(
            draft: draft,
            errors: const {},
            shakeCount: 0,
            onChanged: () {},
          ),
          preview: const Text('Fechas exactas'),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Fechas exactas'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'una respuesta antigua no reemplaza la vista previa recién editada',
    (tester) async {
      final repo = _Repository()
        ..responses.addAll([
          Completer<PlanPreview>(),
          Completer<PlanPreview>(),
        ]);
      await _pump(tester, repo, child: const _PreviewHarness());
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('Cambiar'));
      await tester.pump();
      repo.responses.first.complete(_preview('2030-11-22'));
      await tester.pump();
      expect(find.text('Cargando fechas'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      repo.responses.last.complete(_preview('2030-12-01'));
      await tester.pumpAndSettle();
      expect(find.text('2030-12-01'), findsOneWidget);
      expect(find.text('2030-11-22'), findsNothing);
    },
  );
}
