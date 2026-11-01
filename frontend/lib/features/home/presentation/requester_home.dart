import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/data/auth_models.dart';
import '../../notifications/data/notice_providers.dart';
import '../../orders/data/order_models.dart';
import '../../orders/data/order_providers.dart';
import 'widgets/home_grid.dart';
import 'widgets/home_header.dart';
import 'widgets/home_page.dart';
import 'live_mission.dart';
import 'widgets/home_spotlight.dart';
import 'widgets/quick_tile.dart';
import 'widgets/requester/next_delivery_card.dart';
import 'widgets/requester/requester_stats.dart';
import 'widgets/sign_out.dart';

/// Inicio del solicitante. Con un pedido en el aire, arriba va la misión en
/// curso con la telemetría en vivo de ese vuelo (el mismo socket del mapa,
/// abierto solo mientras se ve el inicio); si no, el dron sobre el radar
/// con cuántos pedidos van en curso. Debajo, sus números, la próxima
/// entrega programada y los accesos para pedir y seguir. Los pedidos salen
/// de `mineProvider` y `plansProvider` y se refrescan cada 10 s.
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
    final open = orders?.where((o) => !_closed.contains(o.status)).toList();
    // El regreso del dron no se le muestra al solicitante.
    final flying = orders
        ?.where((o) => o.hasFlight && o.status != OrderStatus.returning)
        .firstOrNull;
    final next = _nextScheduled(orders);
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
            tagline: flying == null
                ? 'Medicamentos por dron en Valledupar'
                : 'Tu ${flying.medicationName.split(' ').first.toLowerCase()} '
                      'va en el aire.',
            onSignOut: () => signOut(context, ref),
            onNotices: () => context.push('/notifications'),
            unreadNotices: ref.watch(unreadCountProvider).value,
          ),
          const SizedBox(height: 18),
          if (flying != null)
            LiveMission(order: flying)
          else
            HomeSpotlight(
              value: open?.length,
              label: 'Pedidos\nen curso',
              status: const StatusPill(
                label: 'Ningún dron volando',
                tone: PillTone.neutral,
              ),
            ),
          if (flying == null) const SizedBox(height: 12),
          if (orders != null && orders.isNotEmpty)
            RequesterStats(orders: orders),
          if (next != null)
            NextDeliveryCard(
              order: next,
              onTap: () => context.push('/orders/${next.id}'),
            ),
          _RequesterGrid(
            orders: orders,
            plans: ref.watch(plansProvider).value,
            flying: flying != null,
          ),
        ],
      ),
    );
  }

  /// La entrega programada más próxima que todavía no pasó.
  static Order? _nextScheduled(List<Order>? orders) {
    final now = DateTime.now();
    final upcoming =
        orders
            ?.where(
              (o) =>
                  o.scheduledAt != null &&
                  o.scheduledAt!.isAfter(now) &&
                  (o.status == OrderStatus.scheduled ||
                      o.status == OrderStatus.awaitingConfirmation),
            )
            .toList() ??
        [];
    upcoming.sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    return upcoming.firstOrNull;
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
  final bool flying;

  @override
  Widget build(BuildContext context) {
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
              urgent: flying,
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
      ],
    );
  }
}
