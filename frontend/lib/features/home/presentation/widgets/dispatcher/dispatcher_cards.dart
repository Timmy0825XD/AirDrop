import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../home_access_card.dart';
import 'dispatcher_counts.dart';

/// Abre una ruta, o `null` (candado) si el acceso no está disponible.
typedef AccessOpener = VoidCallback? Function(String path, {bool always});

// Las tarjetas de los tres grupos del inicio del despachador. Son
// funciones y no widgets: `DispatcherActions` las junta en una sola lista
// para que entren en cascada.

/// Lo que hay que atender: cola, programados, por cargar, en vuelo y lo
/// que llega de otra central.
List<Widget> operationCards(
  BuildContext context,
  AccessOpener open,
  DispatcherCounts? counts,
) {
  final colors = Theme.of(context).colorScheme;
  final c = counts;
  return [
    const AccessGroup('OPERACIÓN'),
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
    HomeAccessCard(
      title: 'Traslados entrantes',
      subtitle: 'Lo que otras centrales te envían. Recíbelo con el código.',
      icon: Icons.move_to_inbox_outlined,
      tone: colors.tertiary,
      count: c?.toReceive,
      urgent: true,
      onTap: open('/orders/incoming'),
    ),
  ];
}

/// Mi central e inventario.
List<Widget> hubCards(BuildContext context, AccessOpener open) {
  final colors = Theme.of(context).colorScheme;
  return [
    const AccessGroup('MI CENTRAL'),
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

/// Lo que se le pide a otra central y los planes.
List<Widget> requestCards(BuildContext context, AccessOpener open) {
  final colors = Theme.of(context).colorScheme;
  return [
    const AccessGroup('PEDIR A OTRA CENTRAL'),
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

/// El rótulo de un grupo de accesos.
class AccessGroup extends StatelessWidget {
  const AccessGroup(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(text, style: Theme.of(context).textTheme.labelSmall),
  );
}
