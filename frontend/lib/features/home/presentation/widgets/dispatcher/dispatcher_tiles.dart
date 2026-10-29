import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/metric_tile.dart';
import '../../../../../core/widgets/status_pill.dart';
import '../../../../hubs/data/hub_models.dart';
import '../home_grid.dart';
import '../quick_tile.dart';
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
  Color tone(PillTone t) => StatusPill.colorOf(context, t);
  return [
    MetricTile(
      label: 'Por cargar',
      value: c?.pendingLoad,
      caption: 'El dron espera el insumo',
      color: tone(PillTone.attention),
      onTap: open('/orders/pending-load', push: true),
    ),
    MetricTile(
      label: 'En vuelo',
      value: c?.inFlight,
      caption: 'Ida, entrega o regreso',
      color: tone(PillTone.positive),
      onTap: open('/orders/in-flight', push: true),
    ),
    MetricTile(
      label: 'Por recibir',
      value: c?.toReceive,
      caption: 'Traslados en tu central',
      onTap: open('/orders/incoming', push: true),
    ),
    MetricTile(
      label: 'Programados',
      value: c?.scheduled,
      caption: 'Entregas por soltar',
      onTap: open('/orders/scheduled'),
    ),
  ];
}

/// La cola, la central, el inventario y lo que se pide a otra central.
List<Widget> dispatcherHubTiles(
  BuildContext context,
  AccessOpener open,
  DispatcherCounts? c,
) => [
  QuickTile(
    title: 'Cola de urgencias',
    icon: Icons.format_list_numbered_rounded,
    count: c?.queue,
    urgent: true,
    onTap: open('/orders/queue'),
  ),
  QuickTile(
    title: 'Mi central',
    icon: Icons.home_work_outlined,
    onTap: open('/hubs/me', always: true, push: true),
  ),
  QuickTile(
    title: 'Inventario',
    icon: Icons.medication_outlined,
    onTap: open('/inventory'),
  ),
  QuickTile(
    title: 'Urgencia a otra central',
    icon: Icons.swap_horiz_rounded,
    onTap: open('/orders/hub-emergency', push: true),
  ),
  QuickTile(
    title: 'Abastecimiento',
    icon: Icons.calendar_month_outlined,
    onTap: open('/orders/hub-plans/new', push: true),
  ),
  QuickTile(
    title: 'Mis planes',
    icon: Icons.event_repeat_outlined,
    onTap: () => context.push('/orders/plans'),
  ),
];

/// Las bandejas del despachador en cifras y sus accesos en cuadrícula. Sin
/// central activa todo queda con candado menos Mi central y Mis planes.
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
        const HomeLabel('Operación'),
        HomeGrid(children: dispatcherOperationTiles(context, open, counts)),
        const HomeLabel('Tu central y pedidos'),
        HomeGrid(
          startIndex: 4,
          children: dispatcherHubTiles(context, open, counts),
        ),
      ],
    );
  }
}
