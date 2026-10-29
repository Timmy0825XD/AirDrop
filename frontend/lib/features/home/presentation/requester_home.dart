import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/data/auth_models.dart';
import '../../orders/data/order_models.dart';
import '../../orders/data/order_providers.dart';
import 'widgets/home_grid.dart';
import 'widgets/home_header.dart';
import 'widgets/home_page.dart';
import 'widgets/home_spotlight.dart';
import 'widgets/quick_tile.dart';
import 'widgets/requester/flight_spotlight_card.dart';
import 'widgets/sign_out.dart';
import '../../notifications/data/notice_providers.dart';

/// Inicio del solicitante: el saludo, el dron con cuántos pedidos van en
/// curso, el vuelo que esté en el aire (con su atajo al mapa), sus números
/// y los accesos para pedir y seguir. Todo sale de `mineProvider` y
/// `plansProvider` y se refresca cada 10 s.
class RequesterHome extends ConsumerWidget {
  const RequesterHome({super.key, required this.user});

  final PublicUser user;

  /// Estados en los que el pedido ya terminó.
  static const _closed = {
    OrderStatus.delivered,
    OrderStatus.returned,
    OrderStatus.rejected,
    OrderStatus.cancelled,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(mineProvider).value;
    final plans = ref.watch(plansProvider).value;
    final open = orders?.where((o) => !_closed.contains(o.status)).toList();
    final flying = orders?.where((o) => o.hasFlight).toList() ?? const [];
    return AutoRefresh(
      onTick: () => ref
        ..invalidate(mineProvider)
        ..invalidate(plansProvider)
        ..invalidate(unreadCountProvider),
      child: HomePage(
        children: [
          HomeHeader(
            roleLabel: 'Solicitante',
            fullName: user.fullName,
            tagline: 'Medicamentos por dron en Valledupar',
            onSignOut: () => signOut(context, ref),
            onNotices: () => context.push('/notifications'),
            unreadNotices: ref.watch(unreadCountProvider).value,
          ),
          const SizedBox(height: 8),
          HomeSpotlight(
            value: open?.length,
            label: 'Pedidos\nen curso',
            status: flying.isEmpty
                ? const StatusPill(
                    label: 'Ningún dron volando',
                    tone: PillTone.neutral,
                  )
                : const StatusPill(
                    label: 'Dron en camino',
                    tone: PillTone.positive,
                  ),
          ),
          const SizedBox(height: 16),
          if (flying.isNotEmpty)
            FlightSpotlightCard(
              order: flying.first,
              onWatch: () => context.push('/tracking/${flying.first.id}'),
            ),
          _RequesterGrid(orders: orders, plans: plans, flying: flying.length),
        ],
      ),
    );
  }
}

class _RequesterGrid extends StatelessWidget {
  const _RequesterGrid({
    required this.orders,
    required this.plans,
    required this.flying,
  });

  final List<Order>? orders;
  final List<DeliveryPlan>? plans;
  final int flying;

  @override
  Widget build(BuildContext context) {
    final active = plans?.where((p) => p.status == PlanStatus.active).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeLabel('Pedir y seguir'),
        HomeGrid(
          children: [
            QuickTile(
              title: 'Pedir urgencia',
              subtitle: 'Un medicamento, a donde estés.',
              icon: Icons.bolt_rounded,
              onTap: () => context.push('/orders/emergency'),
            ),
            QuickTile(
              title: 'Entrega periódica',
              subtitle: 'Tu tratamiento, cada semana o mes.',
              icon: Icons.calendar_month_outlined,
              onTap: () => context.push('/orders/plans/new'),
            ),
            QuickTile(
              title: 'Mis pedidos',
              icon: Icons.receipt_long_outlined,
              count: orders?.length,
              urgent: flying > 0,
              onTap: () => context.go('/orders/mine'),
            ),
            QuickTile(
              title: 'Mis planes',
              icon: Icons.event_repeat_outlined,
              count: plans?.length,
              onTap: () => context.go('/orders/plans'),
            ),
          ],
        ),
        const HomeLabel('Tus números'),
        HomeGrid(
          startIndex: 4,
          children: [
            MetricTile(label: 'Volando', value: orders == null ? null : flying),
            MetricTile(label: 'Planes activos', value: active),
          ],
        ),
      ],
    );
  }
}
