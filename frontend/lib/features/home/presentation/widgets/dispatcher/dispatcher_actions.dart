import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/rise_in.dart';
import '../../../../hubs/data/hub_models.dart';
import '../home_access_card.dart';
import 'dispatcher_counts.dart';

/// Abre una ruta, o `null` (candado) si el acceso no está disponible.
typedef _Opener = VoidCallback? Function(String path, {bool always});

/// Los accesos del despachador en tres grupos: lo que hay que atender, su
/// central y lo que le pide a otra central. Sin central activa todo queda
/// con candado menos Mi central y Mis planes. Entran en cascada.
class DispatcherActions extends StatelessWidget {
  const DispatcherActions({super.key, required this.hub, required this.counts});

  final Hub? hub;
  final DispatcherCounts? counts;

  @override
  Widget build(BuildContext context) {
    final active = hub?.isActive ?? false;
    VoidCallback? open(String path, {bool always = false}) =>
        active || (always && hub != null) ? () => context.go(path) : null;
    final cards = [
      ..._operationCards(context, open),
      ..._hubCards(context, open),
      ..._requestCards(context, open),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, card) in cards.indexed)
          RiseIn(
            delay: RiseIn.stagger(i + 2),
            child: Padding(
              padding: EdgeInsets.only(bottom: card is _Group ? 12 : 10),
              child: card,
            ),
          ),
      ],
    );
  }

  List<Widget> _operationCards(BuildContext context, _Opener open) {
    final colors = Theme.of(context).colorScheme;
    final c = counts;
    return [
      const _Group('OPERACIÓN'),
      HomeAccessCard(
        title: 'Cola de urgencias',
        subtitle: 'Urgencias en recibido que tu central puede atender.',
        icon: Icons.emergency_outlined,
        tone: colors.error,
        count: c?.queue,
        urgent: true,
        onTap: open('/orders/queue'),
      ),
      HomeAccessCard(
        title: 'Programados',
        subtitle: 'Entregas periódicas que tu central puede soltar.',
        icon: Icons.event_available_outlined,
        tone: colors.primary,
        count: c?.scheduled,
        onTap: open('/orders/scheduled'),
      ),
      HomeAccessCard(
        title: 'Pendiente de carga',
        subtitle: 'Autorizados: el dron espera el insumo.',
        icon: Icons.inventory_outlined,
        tone: colors.primary,
        count: c?.pendingLoad,
        urgent: true,
        onTap: open('/orders/pending-load'),
      ),
      HomeAccessCard(
        title: 'Vuelos en curso',
        subtitle: 'En el aire o esperando la entrega.',
        icon: Icons.flight_rounded,
        tone: colors.secondary,
        count: c?.inFlight,
        onTap: open('/orders/in-flight'),
      ),
    ];
  }

  List<Widget> _hubCards(BuildContext context, _Opener open) {
    final colors = Theme.of(context).colorScheme;
    return [
      const _Group('MI CENTRAL'),
      HomeAccessCard(
        title: 'Mi central',
        subtitle: 'Datos, contacto y ubicación.',
        icon: Icons.home_work_outlined,
        tone: colors.primary,
        onTap: open('/hubs/me', always: true),
      ),
      HomeAccessCard(
        title: 'Inventario',
        subtitle: 'Insumos, lotes y vencimientos.',
        icon: Icons.medication_outlined,
        tone: colors.tertiary,
        onTap: open('/inventory'),
      ),
    ];
  }

  List<Widget> _requestCards(BuildContext context, _Opener open) {
    final colors = Theme.of(context).colorScheme;
    return [
      const _Group('PEDIR A OTRA CENTRAL'),
      HomeAccessCard(
        title: 'Urgencia',
        subtitle: 'Un insumo que tu central necesita ya.',
        icon: Icons.swap_horiz_rounded,
        tone: colors.secondary,
        onTap: open('/orders/hub-emergency'),
      ),
      HomeAccessCard(
        title: 'Abastecimiento',
        subtitle: 'Entregas periódicas desde otra central.',
        icon: Icons.calendar_month_outlined,
        tone: colors.primary,
        onTap: open('/orders/hub-plans/new'),
      ),
      HomeAccessCard(
        title: 'Mis planes',
        subtitle: 'Fechas, extensión y cancelación.',
        icon: Icons.event_repeat_outlined,
        tone: colors.primary,
        onTap: () => context.go('/orders/plans'),
      ),
    ];
  }
}

/// El rótulo de un grupo de accesos.
class _Group extends StatelessWidget {
  const _Group(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(text, style: Theme.of(context).textTheme.labelSmall),
  );
}
