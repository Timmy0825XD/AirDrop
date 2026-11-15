import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock/sim_clock.dart';
import '../../../core/widgets/auto_refresh.dart';
import '../../../core/widgets/menu_list.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/data/auth_models.dart';
import '../../notifications/data/notice_providers.dart';
import '../../orders/data/order_models.dart';
import '../../orders/data/order_providers.dart';
import '../../orders/presentation/order_history_screen.dart';
import '../../settings/data/app_settings.dart';
import 'widgets/home_grid.dart';
import 'widgets/home_header.dart';
import 'widgets/home_page.dart';
import 'live_mission.dart';
import 'widgets/home_spotlight.dart';
import 'widgets/requester/first_order_card.dart';
import 'widgets/requester/next_delivery_card.dart';
import 'widgets/requester/requester_stats.dart';

/// Inicio del solicitante. Con un pedido en el aire, arriba va la misión en
/// curso con la telemetría en vivo de ese vuelo (el mismo socket del mapa,
/// abierto solo mientras se ve el inicio); si no, cuántos pedidos van en
/// curso, o la invitación a pedir la primera urgencia si no hay ninguno. Debajo, sus números, la próxima
/// entrega programada y "Entrega periódica" (pedir urgencia, Mis pedidos y
/// Mis planes ya están en la barra). La cifra abre Mis pedidos en curso.
/// Los pedidos salen de `mineProvider` y se refrescan cada 10 s.
class RequesterHome extends ConsumerWidget {
  const RequesterHome({super.key, required this.user});

  final PublicUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(mineProvider).value;
    final open = orders?.where(isRequesterOrderOpen).toList();
    // El regreso del dron no se le muestra al solicitante.
    final flying = orders
        ?.where((o) => o.hasFlight && o.status != OrderStatus.returning)
        .firstOrNull;
    final next = _nextScheduled(orders);
    final simple = ref.watch(settingsProvider).simpleMode;
    final first = orders != null && orders.isEmpty;
    return AutoRefresh(
      onTick: () => ref
        ..invalidate(mineProvider)
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
            onProfile: () => context.go('/profile'),
            onNotices: () => context.push('/notifications'),
            unreadNotices: ref.watch(unreadCountProvider).value,
          ),
          const SizedBox(height: 18),
          if (flying != null)
            LiveMission(order: flying, forRequester: true)
          else if (orders != null && orders.isEmpty)
            FirstOrderCard(onOrder: () => context.push('/orders/emergency'))
          else
            HomeSpotlight(
              value: open?.length,
              label: 'Pedidos\nen curso',
              onTap: () => context.go(OrderHistoryScreen.openPath),
              status: const StatusPill(
                label: 'Ningún dron volando',
                tone: PillTone.neutral,
              ),
            ),
          if (flying == null && (orders?.isNotEmpty ?? true))
            const SizedBox(height: 12),
          // En modo sencillo no hay pestaña de urgencia: es el botón grande.
          if (simple && !first)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/orders/emergency'),
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Pedir urgencia'),
              ),
            ),
          if (!simple && orders != null && orders.isNotEmpty)
            RequesterStats(orders: orders),
          if (next != null)
            NextDeliveryCard(
              order: next,
              onTap: () => context.push('/orders/${next.id}'),
            ),
          _RequesterGrid(simple: simple),
        ],
      ),
    );
  }

  /// La entrega programada más próxima que todavía no pasó.
  static Order? _nextScheduled(List<Order>? orders) {
    final now = simClock.now();
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

/// Lo único que la barra no tiene: pedir una entrega periódica. Pedir
/// urgencia es la pestaña del centro; Mis pedidos y Mis planes, destinos.
class _RequesterGrid extends StatelessWidget {
  const _RequesterGrid({required this.simple});

  /// En modo sencillo "Mis planes" no está en la barra: va aquí.
  final bool simple;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeLabel(simple ? 'Entregas periódicas' : 'Pedir'),
        MenuList(
          items: [
            if (simple)
              MenuItem(
                title: 'Mis planes',
                subtitle: 'Las entregas que ya programaste',
                icon: Icons.event_repeat_rounded,
                onTap: () => context.push('/orders/plans'),
              ),
            MenuItem(
              title: 'Entrega periódica',
              subtitle: 'Tu tratamiento, cada semana o mes',
              icon: Icons.calendar_month_rounded,
              onTap: () => context.push('/orders/plans/new'),
            ),
          ],
        ),
      ],
    );
  }
}
