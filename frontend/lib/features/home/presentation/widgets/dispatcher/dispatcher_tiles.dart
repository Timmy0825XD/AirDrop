import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/menu_list.dart';
import '../../../../../core/widgets/metric_tile.dart';
import '../../../../../core/widgets/rise_in.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../hubs/data/hub_models.dart';
import '../home_grid.dart';
import 'dispatcher_counts.dart';

/// Abre una ruta, o `null` (candado) si el acceso no está disponible.
typedef AccessOpener =
    VoidCallback? Function(String path, {bool always, bool push});

// Las cifras y los accesos son funciones y no widgets: `DispatcherTiles`
// los reparte en cuadrículas que entran en cascada.

/// Las bandejas en cifras: por cargar, en vuelo, por recibir, programados.
List<Widget> dispatcherOperationTiles(
  BuildContext context,
  AccessOpener open,
  DispatcherCounts? c,
) {
  // En 0 la cifra va en gris: nada pide atención ahí.
  final muted = Theme.of(context).colorScheme.onSurfaceVariant;
  Color? tone(int? value, PillTone? t) => value == 0
      ? muted
      : t == null
      ? null
      : StatusPill.colorOf(context, t);
  return [
    MetricTile(
      label: 'Por cargar',
      value: c?.pendingLoad,
      caption: 'El dron espera el insumo',
      color: tone(c?.pendingLoad, PillTone.attention),
      onTap: open('/orders/pending-load', push: true),
    ),
    MetricTile(
      label: 'En vuelo',
      value: c?.inFlight,
      caption: 'Ida, entrega o regreso',
      color: tone(c?.inFlight, PillTone.positive),
      onTap: open('/orders/in-flight', push: true),
    ),
    MetricTile(
      label: 'Por recibir',
      value: c?.toReceive,
      caption: 'Traslados en tu central',
      color: tone(c?.toReceive, null),
      onTap: open('/orders/incoming', push: true),
    ),
    MetricTile(
      label: 'Programados',
      value: c?.scheduled,
      caption: 'Entregas por soltar',
      color: tone(c?.scheduled, null),
      onTap: open('/orders/scheduled'),
    ),
  ];
}

/// La central y lo que se pide a otra central. La cola y el inventario no
/// van: ya están en la barra.
List<MenuItem> dispatcherHubItems(BuildContext context, AccessOpener open) => [
  MenuItem(
    title: 'Mi central',
    subtitle: 'Datos, horario y estado',
    icon: Icons.home_work_outlined,
    onTap: open('/hubs/me', always: true, push: true),
  ),
  MenuItem(
    title: 'Urgencia a otra central',
    subtitle: 'Pide un insumo que no tienes',
    icon: Icons.swap_horiz_rounded,
    onTap: open('/orders/hub-emergency', push: true),
  ),
  MenuItem(
    title: 'Nuevo abastecimiento',
    subtitle: 'Entregas periódicas a tu central',
    icon: Icons.calendar_month_outlined,
    onTap: open('/orders/hub-plans/new', push: true),
  ),
  MenuItem(
    title: 'Mis abastecimientos',
    icon: Icons.event_repeat_outlined,
    onTap: () => context.push('/orders/plans'),
  ),
];

/// Las bandejas del despachador en cifras y sus accesos en cuadrícula. Sin
/// central activa todo queda con candado menos Mi central y Mis
/// abastecimientos.
class DispatcherTiles extends StatelessWidget {
  const DispatcherTiles({super.key, required this.hub, required this.counts});

  final Hub? hub;
  final DispatcherCounts? counts;

  @override
  Widget build(BuildContext context) {
    final active = hub?.isActive ?? false;
    VoidCallback? open(String path, {bool always = false, bool push = false}) {
      if (!active && !(always && hub != null)) return null;
      return () => push ? context.push(path) : context.go(path);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeLabel('Hoy en la central'),
        HomeGrid(children: dispatcherOperationTiles(context, open, counts)),
        const HomeLabel('Tu central y pedidos'),
        RiseIn(
          delay: RiseIn.stagger(4),
          child: MenuList(items: dispatcherHubItems(context, open)),
        ),
      ],
    );
  }
}
