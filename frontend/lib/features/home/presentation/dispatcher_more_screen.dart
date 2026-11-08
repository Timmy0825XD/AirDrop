import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../hubs/data/hub_providers.dart';
import 'widgets/dispatcher/dispatcher_counts.dart';
import 'widgets/home_grid.dart';
import 'widgets/quick_tile.dart';
import 'widgets/section_header.dart';

/// Abre una ruta, o `null` (candado) si la central no lo permite.
typedef MoreOpen = VoidCallback? Function(String path, {bool always});

/// Pedidos de la central: lo que llega, lo que sale y lo que pasó.
List<Widget> _orderTiles(MoreOpen open, DispatcherCounts? counts) => [
  QuickTile(
    title: 'Traslados entrantes',
    icon: Icons.move_to_inbox_outlined,
    count: counts?.toReceive,
    urgent: true,
    onTap: open('/orders/incoming'),
  ),
  QuickTile(
    title: 'Pendiente de carga',
    icon: Icons.inventory_2_outlined,
    count: counts?.pendingLoad,
    urgent: true,
    onTap: open('/orders/pending-load'),
  ),
  QuickTile(
    title: 'Vuelos en curso',
    icon: Icons.near_me_rounded,
    count: counts?.inFlight,
    onTap: open('/orders/in-flight'),
  ),
  QuickTile(
    title: 'Programados',
    icon: Icons.event_note_outlined,
    onTap: open('/orders/scheduled'),
  ),
  QuickTile(
    title: 'Histórico',
    icon: Icons.history_rounded,
    onTap: open('/orders/history'),
  ),
];

/// Lo que esta central le pide a otra: una urgencia o un abastecimiento.
List<Widget> _requestTiles(BuildContext context, MoreOpen open) => [
  QuickTile(
    title: 'Urgencia a otra central',
    icon: Icons.swap_horiz_rounded,
    onTap: open('/orders/hub-emergency'),
  ),
  QuickTile(
    title: 'Nuevo abastecimiento',
    icon: Icons.calendar_month_outlined,
    onTap: open('/orders/hub-plans/new'),
  ),
  QuickTile(
    title: 'Mis abastecimientos',
    icon: Icons.event_repeat_outlined,
    onTap: () => context.push('/orders/plans'),
  ),
];

/// La central y la cuenta. Cerrar sesión está dentro del perfil.
List<Widget> _hubTiles(BuildContext context, MoreOpen open) => [
  QuickTile(
    title: 'Mi central',
    icon: Icons.home_work_outlined,
    onTap: open('/hubs/me', always: true),
  ),
  QuickTile(
    title: 'Cuarentena',
    icon: Icons.health_and_safety_outlined,
    onTap: open('/inventory/quarantine'),
  ),
  QuickTile(
    title: 'Perfil',
    icon: Icons.person_outline_rounded,
    onTap: () => context.push('/profile'),
  ),
];

/// "Más" del despachador: lo que no cabe en la barra, en tres grupos
/// (Pedidos · Pedir a otra central · Mi central). Mi central, Mis
/// abastecimientos y el perfil siempre; lo demás, solo con la central
/// activa.
class DispatcherMoreScreen extends ConsumerWidget {
  const DispatcherMoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(myHubProvider).value;
    final active = hub?.isActive ?? false;
    final counts = active ? DispatcherCounts.watch(ref) : null;
    VoidCallback? open(String path, {bool always = false}) =>
        active || (always && hub != null) ? () => context.push(path) : null;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          SectionHeader(
            title: 'Más',
            subtitle: hub?.name ?? 'Tu central',
            onBack: () => SectionHeader.backOrHome(context),
          ),
          _MoreGroup('Pedidos', _orderTiles(open, counts)),
          _MoreGroup('Pedir a otra central', _requestTiles(context, open)),
          _MoreGroup('Mi central', _hubTiles(context, open)),
        ],
      ),
    );
  }
}

/// Un grupo de "Más": su rótulo y la cuadrícula.
class _MoreGroup extends StatelessWidget {
  const _MoreGroup(this.label, this.tiles);

  final String label;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeLabel(label),
          HomeGrid(children: tiles),
        ],
      ),
    );
  }
}
