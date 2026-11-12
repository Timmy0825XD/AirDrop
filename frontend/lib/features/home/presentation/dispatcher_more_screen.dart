import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/menu_list.dart';
import '../../hubs/data/hub_providers.dart';
import 'widgets/dispatcher/dispatcher_counts.dart';
import 'widgets/home_grid.dart';
import 'widgets/section_header.dart';

/// Abre una ruta, o `null` (candado) si la central no lo permite.
typedef MoreOpen = VoidCallback? Function(String path, {bool always});

/// Pedidos de la central: lo que llega, lo que sale y lo que pasó.
List<MenuItem> _orderItems(MoreOpen open, DispatcherCounts? counts) => [
  MenuItem(
    title: 'Traslados entrantes',
    subtitle: 'Lo que otra central te envía',
    icon: Icons.move_to_inbox_outlined,
    count: counts?.toReceive,
    urgent: true,
    onTap: open('/orders/incoming'),
  ),
  MenuItem(
    title: 'Pendiente de carga',
    subtitle: 'El dron espera el insumo',
    icon: Icons.inventory_2_outlined,
    count: counts?.pendingLoad,
    urgent: true,
    onTap: open('/orders/pending-load'),
  ),
  MenuItem(
    title: 'Vuelos en curso',
    subtitle: 'Ida, entrega o regreso',
    icon: Icons.near_me_outlined,
    count: counts?.inFlight,
    onTap: open('/orders/in-flight'),
  ),
  MenuItem(
    title: 'Programados',
    subtitle: 'Entregas por soltar',
    icon: Icons.event_note_outlined,
    onTap: open('/orders/scheduled'),
  ),
  MenuItem(
    title: 'Histórico',
    subtitle: 'Lo que ya cerró',
    icon: Icons.history_rounded,
    onTap: open('/orders/history'),
  ),
];

/// Lo que esta central le pide a otra: una urgencia o un abastecimiento.
List<MenuItem> _requestItems(BuildContext context, MoreOpen open) => [
  MenuItem(
    title: 'Urgencia a otra central',
    icon: Icons.swap_horiz_rounded,
    onTap: open('/orders/hub-emergency'),
  ),
  MenuItem(
    title: 'Nuevo abastecimiento',
    icon: Icons.calendar_month_outlined,
    onTap: open('/orders/hub-plans/new'),
  ),
  MenuItem(
    title: 'Mis abastecimientos',
    icon: Icons.event_repeat_outlined,
    onTap: () => context.push('/orders/plans'),
  ),
];

/// La central y la cuenta. Cerrar sesión está dentro del perfil.
List<MenuItem> _hubItems(BuildContext context, MoreOpen open) => [
  MenuItem(
    title: 'Mi central',
    icon: Icons.home_work_outlined,
    onTap: open('/hubs/me', always: true),
  ),
  MenuItem(
    title: 'Cuarentena',
    subtitle: 'Insumos devueltos en revisión',
    icon: Icons.health_and_safety_outlined,
    onTap: open('/inventory/quarantine'),
  ),
  MenuItem(
    title: 'Perfil',
    icon: Icons.person_outline_rounded,
    onTap: () => context.push('/profile'),
  ),
];

/// "Más" del despachador: lo que no cabe en la barra, en tres listas
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
        // El encabezado y los grupos llevan su propio margen de lado.
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 32,
        ),
        children: [
          SectionHeader(
            title: 'Más',
            subtitle: hub?.name ?? 'Tu central',
            onBack: () => SectionHeader.backOrHome(context),
          ),
          _MoreGroup('Pedidos', _orderItems(open, counts)),
          _MoreGroup('Pedir a otra central', _requestItems(context, open)),
          _MoreGroup('Mi central', _hubItems(context, open)),
        ],
      ),
    );
  }
}

/// Un grupo de "Más": su título y la lista.
class _MoreGroup extends StatelessWidget {
  const _MoreGroup(this.label, this.items);

  final String label;
  final List<MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeLabel(label),
          MenuList(items: items),
        ],
      ),
    );
  }
}
