import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/rise_in.dart';
import '../../auth/data/auth_models.dart';
import '../../orders/data/order_models.dart';
import '../../orders/data/order_providers.dart';
import 'widgets/home_access_card.dart';
import 'widgets/home_stats_card.dart';
import 'widgets/role_hero.dart';
import 'widgets/sign_out.dart';

/// Inicio del solicitante: el saludo, cuántos pedidos van en curso, cuántos
/// van volando y cuántos planes tiene activos, y los accesos para pedir y
/// para seguir lo pedido. Los números salen de sus listas (`mineProvider`,
/// `plansProvider`) y se refrescan cada 10 s.
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
    final flying = orders?.where((o) => o.hasFlight).length;
    return Scaffold(
      body: AutoRefresh(
        onTick: () => ref
          ..invalidate(mineProvider)
          ..invalidate(plansProvider),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                RoleHero(
                  roleLabel: 'Solicitante',
                  firstName: RoleHero.firstNameOf(user.fullName),
                  tagline: 'Medicamentos por dron en Valledupar',
                  onProfile: () => context.push('/profile'),
                  onSignOut: () => signOut(context, ref),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    RoleHero.heightFor(context) - 46,
                    20,
                    0,
                  ),
                  child: RiseIn(
                    delay: const Duration(milliseconds: 150),
                    child: _RequesterStats(orders: orders, plans: plans),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
              child: _RequesterActions(
                orderCount: orders?.length,
                flying: flying ?? 0,
                planCount: plans?.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pedidos en curso, volando y planes activos.
class _RequesterStats extends StatelessWidget {
  const _RequesterStats({required this.orders, required this.plans});

  final List<Order>? orders;
  final List<DeliveryPlan>? plans;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return HomeStatsCard(
      stats: [
        HomeStat(
          value: orders
              ?.where((o) => !RequesterHome._closed.contains(o.status))
              .length,
          label: 'En curso',
          color: colors.primary,
        ),
        HomeStat(
          value: orders?.where((o) => o.hasFlight).length,
          label: 'Volando',
          color: colors.secondary,
        ),
        HomeStat(
          value: plans?.where((p) => p.status == PlanStatus.active).length,
          label: 'Planes activos',
          color: colors.tertiary,
        ),
      ],
    );
  }
}

class _RequesterActions extends StatelessWidget {
  const _RequesterActions({
    required this.orderCount,
    required this.flying,
    required this.planCount,
  });

  final int? orderCount;
  final int flying;
  final int? planCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cards = [
      HomeAccessCard(
        title: 'Pedir urgencia',
        subtitle: 'Un medicamento, a donde estés.',
        icon: Icons.emergency_outlined,
        tone: colors.error,
        onTap: () => context.go('/orders/emergency'),
      ),
      HomeAccessCard(
        title: 'Entrega periódica',
        subtitle: 'Tu tratamiento, cada semana o cada mes.',
        icon: Icons.calendar_month_outlined,
        tone: colors.primary,
        onTap: () => context.go('/orders/plans/new'),
      ),
      HomeAccessCard(
        title: 'Mis pedidos',
        subtitle: flying > 0
            ? 'Tienes un dron en camino: míralo en el mapa.'
            : 'El estado de lo que has pedido.',
        icon: Icons.receipt_long_outlined,
        tone: colors.secondary,
        count: orderCount,
        urgent: flying > 0,
        onTap: () => context.go('/orders/mine'),
      ),
      HomeAccessCard(
        title: 'Mis planes',
        subtitle: 'Fechas, extensión y cancelación.',
        icon: Icons.event_repeat_outlined,
        tone: colors.primary,
        count: planCount,
        onTap: () => context.go('/orders/plans'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RiseIn(
          delay: const Duration(milliseconds: 220),
          child: Text(
            'PEDIR Y SEGUIR',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        const SizedBox(height: 12),
        for (final (i, card) in cards.indexed)
          RiseIn(
            delay: RiseIn.stagger(i + 3),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: card,
            ),
          ),
      ],
    );
  }
}
