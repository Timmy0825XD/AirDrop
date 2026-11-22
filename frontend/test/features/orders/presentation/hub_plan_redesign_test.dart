import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/clock/sim_clock.dart';
import 'package:frontend/core/widgets/auth_field.dart';
import 'package:frontend/features/hubs/data/hub_providers.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/data/order_providers.dart';
import 'package:frontend/features/orders/data/local_order_repository.dart';
import 'package:frontend/features/orders/presentation/hub_plan_form_screen.dart';
import 'package:frontend/theme/app_palette.dart';

const _origin = OriginHub(
  id: 'origin',
  name: 'Central La Paz',
  address: 'La Paz',
);
const _offer = CatalogOffer(
  name: 'Suero oral',
  saleType: SaleType.overTheCounter,
  requiresColdChain: false,
  availableQuantity: 30,
);

class _Create extends CreateHubPlanNotifier {
  CreateHubPlanRequest? request;
  @override
  Future<DeliveryPlan?> build() async => null;
  @override
  Future<DeliveryPlan> create(CreateHubPlanRequest value) async {
    request = value;
    return DeliveryPlan(
      id: 'plan',
      status: PlanStatus.active,
      medicationName: value.medicationName,
      saleType: value.saleType,
      requiresColdChain: false,
      quantity: value.quantity,
      startDate: '2026-11-23',
      windowEndsOn: '2026-12-14',
      destinationKind: DestinationKind.hub,
      address: 'Tu central',
      hasPrescription: false,
      renewalDue: false,
      schedule: value.schedule,
    );
  }
}

Future<void> _bring(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  await tester.scrollUntilVisible(
    target,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.3);
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => simClock.apply(
      ClockView(now: DateTime.utc(2026, 11, 21, 15), speed: 1, paused: true),
    ),
  );
  tearDown(simClock.reset);
  testWidgets(
    'programar conserva origen, insumo y calendario y exige una vista previa válida',
    (tester) async {
      final create = _Create();
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/new',
        routes: [
          GoRoute(path: '/new', builder: (_, _) => const HubPlanFormScreen()),
          GoRoute(
            path: '/orders/plans/:id',
            builder: (_, _) => const Scaffold(body: Text('Plan creado')),
          ),
          GoRoute(path: '/more', builder: (_, _) => const Scaffold()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          retry: (count, error) => null,
          overrides: [
            originHubsProvider.overrideWith((ref) async => [_origin]),
            hubCatalogProvider.overrideWith((ref, id) async => [_offer]),
            myHubProvider.overrideWith((ref) async => null),
            orderRepositoryProvider.overrideWithValue(LocalOrderRepository()),
            createHubPlanProvider.overrideWith(() => create),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData(extensions: const [AppPalette.light]),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: const TextScaler.linear(2),
              ),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _bring(tester, find.text('Elige la central'));
      await tester.tap(find.text('Elige la central'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Central La Paz'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Central La Paz')),
        alignment: 0.3,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Central La Paz'));
      await tester.pumpAndSettle();
      await _bring(tester, find.text('Elige el insumo'));
      await tester.tap(find.text('Elige el insumo'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Suero oral'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Suero oral')),
        alignment: 0.3,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suero oral'));
      await tester.pumpAndSettle();
      final qty = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is AuthField && w.label == 'Cantidad por entrega',
        ),
        matching: find.byType(TextField),
      );
      await _bring(tester, qty);
      await tester.enterText(qty, '20');
      await _bring(tester, find.text('Programar abastecimiento'));
      await tester.tap(find.text('Programar abastecimiento'));
      await tester.pumpAndSettle();
      expect(create.request, isNull);
      await _bring(tester, find.text('L'));
      await tester.tap(find.text('L'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await _bring(tester, find.text('Programar abastecimiento'));
      await tester.tap(find.text('Programar abastecimiento'));
      await tester.pumpAndSettle();
      expect(create.request?.originHubId, 'origin');
      expect(create.request?.quantity, 20);
      expect(create.request?.schedule?.toJson(), {
        'kind': 'weekly',
        'startDate': '2026-11-21',
        'count': 4,
        'daysOfWeek': [1],
        'everyWeeks': 1,
        'time': '10:00',
      });
      expect(find.text('Plan creado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
