import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../hubs/data/hub_providers.dart';
import 'widgets/dispatcher/dispatcher_counts.dart';
import 'widgets/home_grid.dart';
import 'widgets/quick_tile.dart';
import 'widgets/section_header.dart';
import 'widgets/sign_out.dart';

/// Los accesos de "Más". [open] da `null` (candado) a lo que la central
/// no permite.
List<Widget> _moreTiles(
  BuildContext context,
  VoidCallback? Function(String path, {bool always}) open,
  DispatcherCounts? counts,
  VoidCallback onSignOut,
) => [
  QuickTile(
    title: 'Mi central',
    icon: Icons.home_work_outlined,
    onTap: open('/hubs/me', always: true),
  ),
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
  QuickTile(
    title: 'Cuarentena',
    icon: Icons.health_and_safety_outlined,
    onTap: open('/inventory/quarantine'),
  ),
  QuickTile(
    title: 'Urgencia a otra central',
    icon: Icons.swap_horiz_rounded,
    onTap: open('/orders/hub-emergency'),
  ),
  QuickTile(
    title: 'Abastecimiento',
    icon: Icons.calendar_month_outlined,
    onTap: open('/orders/hub-plans/new'),
  ),
  QuickTile(
    title: 'Mis planes',
    icon: Icons.event_repeat_outlined,
    onTap: () => context.push('/orders/plans'),
  ),
  QuickTile(
    title: 'Perfil',
    icon: Icons.person_outline_rounded,
    onTap: () => context.push('/profile'),
  ),
  QuickTile(
    title: 'Cerrar sesión',
    icon: Icons.logout_rounded,
    onTap: onSignOut,
  ),
];

/// "Más" del despachador: lo que no cabe en la barra, en cuadrícula. Mi
/// central y Mis planes siempre; lo demás, solo con la central activa.
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: HomeGrid(
              children: _moreTiles(
                context,
                open,
                counts,
                () => signOut(context, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
