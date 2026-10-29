import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/app_snack.dart';
import 'package:frontend/features/analytics/data/analytics_models.dart';
import 'package:frontend/features/hubs/data/hub_models.dart';
import 'package:frontend/features/hubs/presentation/widgets/hub_form_values.dart';
import 'package:frontend/features/inventory/data/inventory_models.dart';
import 'package:frontend/features/notifications/data/notice_models.dart';
import 'package:frontend/features/orders/data/agenda_models.dart';
import 'package:frontend/features/orders/data/order_models.dart';
import 'package:frontend/features/orders/presentation/order_format.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/authorize_outcome.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/dispatcher_permissions.dart';
import 'package:frontend/features/orders/presentation/widgets/order_detail/occurrence_rules.dart';
import 'package:frontend/features/tracking/data/telemetry_models.dart';
import 'package:latlong2/latlong.dart';

Map<String, dynamic> _orderJson([Map<String, dynamic> extra = const {}]) => {
  'id': 'o1',
  'missionType': 'emergency',
  'destinationKind': 'person',
  'status': 'received',
  'priority': 'high',
  'medicationName': 'Acetaminofén 500 mg',
  'saleType': 'over_the_counter',
  'requiresColdChain': false,
  'quantity': 1,
  'createdByUserId': 'u1',
  'address': 'Calle 16',
  ...extra,
};

void main() {
  group('Order (presentOrder de Nest)', () {
    test('lee el fallback en sus tres tipos y tolera null', () {
      final hub = Order.fromJson(
        _orderJson({
          'status': 'reassigned',
          'reassignedFromHubId': 'h0',
          'fallback': {
            'kind': 'hub',
            'reason': 'Ningún dron de la central podía salir.',
            'options': [
              {
                'hubId': 'h2',
                'name': 'Clínica Norte',
                'address': 'Calle 20',
                'contactPhone': '6055700000',
                'contactEmail': null,
                'distanceKm': 3.2,
              },
            ],
            'retryAfter': null,
            'reassignedAt': '2026-10-29T15:00:00.000Z',
          },
        }),
      );
      expect(hub.fallback?.kind, FallbackKind.hub);
      expect(hub.fallback?.newHub?.name, 'Clínica Norte');
      expect(hub.reassignedToHub, isTrue);

      final retry = Order.fromJson(
        _orderJson({
          'fallback': {
            'kind': 'retry',
            'options': [],
            'retryAfter': '2026-10-29T15:15:00.000Z',
          },
        }),
      );
      expect(retry.fallback?.kind, FallbackKind.retry);
      expect(retry.fallback?.options, isEmpty);

      expect(Order.fromJson(_orderJson({'fallback': null})).fallback, isNull);
      expect(
        Order.fromJson(
          _orderJson({
            'fallback': {'kind': 'nuevo'},
          }),
        ).fallback,
        isNull,
      );
    });

    test('lee frío, lote, retorno y franja', () {
      final order = Order.fromJson(
        _orderJson({
          'status': 'returned',
          'coldChainAlert': true,
          'coldChainAlertAt': '2026-10-29T15:00:00.000Z',
          'dispatchedLot': 'L-1',
          'dispatchedLotExpiresOn': '2027-01-31',
          'returnCheckedAt': null,
          'returnOutcome': null,
          'scheduledAt': '2026-10-30T15:00:00.000Z',
          'windowEndsAt': '2026-10-30T16:00:00.000Z',
        }),
      );
      expect(order.coldChainAlert, isTrue);
      expect(order.dispatchedLot, 'L-1');
      expect(order.awaitsReturnCheck, isTrue);
      expect(
        formatSlot(order.scheduledAt, order.windowEndsAt),
        '10:00 – 11:00',
      );
    });

    test('la ruta de regreso solo cuenta con 2 puntos o más', () {
      final base = {
        'droneId': 'd1',
        'identifier': 'D-01',
        'modelName': 'Wingcopter 198',
        'route': {
          'altitudeM': 100,
          'distanceKm': 4.2,
          'coordinates': [
            [-73.25, 10.46],
            [-73.24, 10.47],
          ],
        },
      };
      expect(OrderAssignment.fromJson(base).hasReturnRoute, isFalse);
      final back = OrderAssignment.fromJson({
        ...base,
        'returnRoute': {
          'altitudeM': 100,
          'distanceKm': 4.4,
          'coordinates': [
            [-73.24, 10.47],
            [-73.26, 10.48],
            [-73.25, 10.46],
          ],
        },
      });
      expect(back.hasReturnRoute, isTrue);
      expect(back.returnCoordinates, hasLength(3));
    });
  });

  group('Telemetría', () {
    test('unloading es en tierra y una fase nueva no rompe el mapa', () {
      expect(FlightPhase.fromJson('unloading').onGround, isTrue);
      expect(FlightPhase.fromJson('hover'), FlightPhase.unknown);
    });

    test('las alertas leen su tipo y toleran uno desconocido', () {
      final cold = FlightAlert.fromJson({
        'orderId': 'o1',
        'droneId': 'd1',
        'kind': 'cold_chain',
        'message': 'La temperatura de la carga salió del rango de 2 a 8 °C.',
      });
      expect(cold.kind, FlightAlertKind.coldChain);
      expect(
        FlightAlert.fromJson({
          'orderId': 'o1',
          'message': 'x',
          'kind': 'y',
        }).kind,
        FlightAlertKind.other,
      );
    });

    test('9 °C es alerta de frío y 5 °C no', () {
      expect(isColdChainBreach(9), isTrue);
      expect(isColdChainBreach(5), isFalse);
      expect(isColdChainBreach(null), isFalse);
    });
  });

  group('Planes con calendario', () {
    test('un plan con frequency null se lee y no se extiende', () {
      final plan = DeliveryPlan.fromJson({
        'id': 'p1',
        'frequency': null,
        'status': 'active',
        'medicationName': 'Suero oral',
        'saleType': 'over_the_counter',
        'requiresColdChain': false,
        'quantity': 2,
        'startDate': '2026-11-03',
        'windowEndsOn': '2026-11-26',
        'destinationKind': 'person',
        'address': 'Calle 16',
        'paused': true,
        'windowMinutes': 60,
        'schedule': {
          'kind': 'weekly',
          'startDate': '2026-11-03',
          'endDate': null,
          'count': 6,
          'daysOfWeek': [2, 4],
          'everyWeeks': 1,
          'dayOfMonth': null,
          'dates': [],
          'time': '10:00',
        },
      });
      expect(plan.frequency, isNull);
      expect(plan.canExtend, isFalse);
      expect(plan.paused, isTrue);
      expect(scheduleLabel(plan), 'Martes y jueves a las 10:00, 6 entregas');
    });

    test('toJson manda solo lo de su tipo', () {
      expect(
        const PlanSchedule(
          kind: ScheduleKind.dates,
          startDate: '2026-11-01',
          count: 3,
          dates: ['2026-11-07'],
          time: '08:00',
        ).toJson(),
        {
          'kind': 'dates',
          'dates': ['2026-11-07'],
          'time': '08:00',
        },
      );
      final until = const PlanSchedule(
        kind: ScheduleKind.weekly,
        startDate: '2026-11-01',
        endDate: '2026-11-30',
        count: 4,
        daysOfWeek: [1],
        time: '07:00',
      ).toJson();
      expect(until['endDate'], '2026-11-30');
      expect(until.containsKey('count'), isFalse, reason: 'nunca los dos');
    });

    test('la vista previa lee tooSoon', () {
      final preview = PlanPreview.fromJson({
        'lastDate': '2026-11-26',
        'windowMinutes': 60,
        'occurrences': [
          {
            'date': '2026-11-05',
            'scheduledAt': '2026-11-05T15:00:00.000Z',
            'windowEndsAt': '2026-11-05T16:00:00.000Z',
          },
        ],
        'tooSoon': ['2026-10-29'],
      });
      expect(preview.occurrences, hasLength(1));
      expect(preview.tooSoon, ['2026-10-29']);
    });
  });

  group('Reglas de pantalla', () {
    Order order({
      OrderStatus status = OrderStatus.received,
      DateTime? scheduledAt,
      String? droneId,
      String? planId,
      String? scheduledFor = '2026-10-30',
    }) => Order(
      id: 'o1',
      missionType: MissionType.scheduled,
      destinationKind: DestinationKind.person,
      status: status,
      priority: OrderPriority.normal,
      medicationName: 'Suero oral',
      saleType: SaleType.overTheCounter,
      requiresColdChain: false,
      quantity: 1,
      address: 'Calle 16',
      hasPrescription: false,
      createdByUserId: 'u1',
      originHubId: 'h1',
      planId: planId,
      scheduledFor: scheduledFor,
      scheduledAt: scheduledAt,
      windowEndsAt: scheduledAt?.add(const Duration(hours: 1)),
      droneId: droneId,
    );

    final now = DateTime.utc(2026, 10, 29, 12);

    test('confirmar y omitir solo sin dron y a 2 horas o más', () {
      final soon = now.add(const Duration(hours: 1));
      final later = now.add(const Duration(hours: 26));
      final waiting = order(
        status: OrderStatus.awaitingConfirmation,
        scheduledAt: later,
        planId: 'p1',
      );
      expect(OccurrenceRules(waiting, now).canConfirm, isTrue);
      expect(
        OccurrenceRules(
          order(
            status: OrderStatus.awaitingConfirmation,
            scheduledAt: soon,
            planId: 'p1',
          ),
          now,
        ).changeable,
        isFalse,
      );
      expect(
        OccurrenceRules(order(scheduledAt: later), now).applies,
        isFalse,
        reason: 'sin plan no es una entrega de plan',
      );
    });

    test('autorizar un programado espera la ventana de 2 horas', () {
      final can = DispatcherPermissions(
        // Sin fecha: `notYet` mira el reloj real; aquí manda la franja.
        order: order(
          scheduledAt: now.add(const Duration(hours: 5)),
          scheduledFor: null,
        ),
        myHubId: 'h1',
      );
      expect(dispatchWindowNote(can.order, now), contains('Disponible desde'));
      final closed = DispatcherPermissions(
        order: order(
          scheduledAt: now.subtract(const Duration(hours: 3)),
          scheduledFor: null,
        ),
        myHubId: 'h1',
      );
      expect(
        dispatchWindowNote(closed.order, now),
        'La franja de esta entrega ya cerró.',
      );
    });

    test('autorizar sin dron se lee del fallback, no de un 409', () {
      final moved = AuthorizeOutcome.of(
        Order.fromJson(
          _orderJson({
            'status': 'reassigned',
            'fallback': {
              'kind': 'hub',
              'options': [
                {'hubId': 'h2', 'name': 'Clínica Norte', 'address': 'x'},
              ],
            },
          }),
        ),
      );
      expect(moved.message, contains('Clínica Norte'));
      expect(moved.leavesHub, isTrue);

      final fenced = AuthorizeOutcome.of(
        Order.fromJson(
          _orderJson({
            'status': 'rejected',
            'statusReason':
                'El destino está dentro de una zona prohibida para drones. '
                'Elige otro punto de entrega.',
          }),
        ),
      );
      expect(fenced.tone, SnackTone.error);
      expect(fenced.message, contains('zona prohibida'));
    });
  });

  group('Otros contratos', () {
    test('la cuarentena tolera un motivo nuevo', () {
      final row = QuarantineRecord.fromJson({
        'id': 'q1',
        'orderId': 'o1',
        'medicationName': 'Insulina',
        'saleType': 'over_the_counter',
        'lot': 'L-1',
        'expirationDate': '2027-01-31',
        'quantity': 1,
        'reason': 'remission_mismatch',
      });
      expect(row.reason, QuarantineReason.other);
    });

    test('un aviso sin pedido y de tipo nuevo se muestra igual', () {
      final notice = AppNotice.fromJson({
        'id': 'n1',
        'kind': 'algo_nuevo',
        'orderId': null,
        'title': 'Hola',
        'body': 'Cuerpo',
        'readAt': null,
      });
      expect(notice.kind, NoticeKind.other);
      expect(notice.unread, isTrue);
      expect(notice.read(DateTime.utc(2026)).unread, isFalse);
    });

    test('la agenda tolera departBefore y prescriptionValid en null', () {
      final day = AgendaDay.fromJson({
        'date': '2026-11-05',
        'drones': 1,
        'slots': [
          {
            'time': '10:00',
            'deliveries': 2,
            'overCapacity': true,
            'orders': [
              _orderJson({
                'time': '10:00',
                'confirmed': true,
                'stockOk': false,
                'availableQuantity': 0,
                'prescriptionValid': null,
                'departBefore': null,
              }),
            ],
          },
        ],
      });
      final entry = day.slots.single.orders.single;
      expect(entry.departBefore, isNull);
      expect(entry.prescriptionValid, isNull);
      expect(day.slots.single.overCapacity, isTrue);
    });

    test('el histórico sabe si hay otra página', () {
      final page = HistoryPage.fromJson({
        'items': [_orderJson()],
        'total': 21,
        'page': 1,
        'pageSize': 20,
      });
      expect(page.hasMore, isTrue);
    });

    test('un KPI sin datos ni meta se lee como informativo', () {
      final kpi = Kpi.fromJson({
        'key': 'returnRate',
        'label': 'Retornos',
        'unit': '%',
        'value': null,
        'target': null,
        'status': 'none',
      });
      expect(kpi.value, isNull);
      expect(kpi.target, isNull);
      expect(kpi.status, KpiStatus.none);
    });

    test('editar una central manda solo lo que cambió', () {
      const hub = Hub(
        id: 'h1',
        name: 'Clínica Norte',
        type: HubType.clinic,
        address: 'Calle 20',
        latitude: 10.48,
        longitude: -73.24,
        contactPhone: '3001234567',
        status: HubStatus.active,
      );
      final values = HubFormValues()..load(hub);
      addTearDown(values.dispose);
      expect(values.changes(hub), isEmpty);
      values.name.text = 'Clínica Norte II';
      expect(values.changes(hub), {'name': 'Clínica Norte II'});
      values.location = const LatLng(10.49, -73.24);
      expect(values.changes(hub).keys, containsAll(['latitude', 'longitude']));
    });
  });

  testWidgets('el aviso de vidrio muestra su texto y su acción', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppSnack(
                context,
                'Pedido autorizado.',
                actionLabel: 'Ver',
                onAction: () => tapped = true,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(GlassSnack), findsOneWidget);
    expect(find.text('Pedido autorizado.'), findsOneWidget);
    await tester.tap(find.text('Ver'));
    expect(tapped, isTrue);
  });
}
