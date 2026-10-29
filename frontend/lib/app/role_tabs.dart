import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/floating_nav_bar.dart';
import '../features/auth/data/auth_models.dart';
import '../features/home/presentation/widgets/admin/admin_create_sheet.dart';
import '../features/fleet/data/fleet_providers.dart';
import '../features/hubs/data/hub_providers.dart';
import '../features/orders/data/order_providers.dart';

/// Los destinos de la barra de cada rol y su acción del centro.
///
/// - Solicitante: Inicio · Pedidos · (Pedir urgencia) · Planes · Perfil.
/// - Despachador: Inicio · Agenda (los programados) · (Cola de urgencias) ·
///   Inventario · Más. La cola también es destino: la abre el botón del centro.
/// - Operador: Inicio · Flota · (Vuelos en curso) · Geovallas · Perfil. El
///   botón abre el mapa de cada dron en misión; "Nuevo dron" está en Flota.
/// - Administrador: Resumen · Centrales · (Nueva) · Cuentas · Perfil.
class RoleTabs {
  const RoleTabs({
    required this.destinations,
    required this.paths,
    required this.center,
    this.centerPath,
  });

  final List<NavDestination> destinations;
  final List<String> paths;
  final NavCenterAction center;

  /// Ruta que abre el botón del centro cuando es un destino más.
  final String? centerPath;

  int? indexOf(String location) {
    final i = paths.indexOf(location);
    return i < 0 ? null : i;
  }

  bool isTab(String location) =>
      paths.contains(location) || location == centerPath;

  static RoleTabs of(UserRole role, BuildContext context, WidgetRef ref) =>
      switch (role) {
        UserRole.requester => _requester(context),
        UserRole.dispatcher => _dispatcher(context, ref),
        UserRole.fleetOperator => _operator(context, ref),
        UserRole.admin => _admin(context),
      };

  static const _home = NavDestination(
    icon: Icons.space_dashboard_outlined,
    label: 'Inicio',
  );
  static const _profile = NavDestination(
    icon: Icons.person_outline_rounded,
    label: 'Perfil',
  );

  static RoleTabs _requester(BuildContext context) => RoleTabs(
    destinations: const [
      _home,
      NavDestination(icon: Icons.receipt_long_outlined, label: 'Pedidos'),
      NavDestination(icon: Icons.event_repeat_outlined, label: 'Planes'),
      _profile,
    ],
    paths: const ['/home', '/orders/mine', '/orders/plans', '/profile'],
    center: NavCenterAction(
      icon: Icons.bolt_rounded,
      label: 'Pedir urgencia',
      onPressed: () => context.push('/orders/emergency'),
    ),
  );

  static RoleTabs _dispatcher(BuildContext context, WidgetRef ref) {
    final active = ref.watch(myHubProvider).value?.isActive ?? false;
    final queue = active ? ref.watch(queueProvider).value?.length : null;
    return RoleTabs(
      destinations: const [
        _home,
        NavDestination(icon: Icons.event_available_outlined, label: 'Agenda'),
        NavDestination(icon: Icons.medication_outlined, label: 'Inventario'),
        NavDestination(icon: Icons.grid_view_rounded, label: 'Más'),
      ],
      paths: const ['/home', '/orders/scheduled', '/inventory', '/more'],
      centerPath: '/orders/queue',
      center: NavCenterAction(
        icon: Icons.format_list_numbered_rounded,
        label: 'Cola de urgencias',
        badge: queue,
        onPressed: () => context.go('/orders/queue'),
      ),
    );
  }

  static RoleTabs _operator(BuildContext context, WidgetRef ref) {
    final flying = ref.watch(fleetFlightsProvider).value?.length;
    return RoleTabs(
      destinations: const [
        _home,
        NavDestination(icon: Icons.flight_rounded, label: 'Flota'),
        NavDestination(icon: Icons.hexagon_outlined, label: 'Geovallas'),
        _profile,
      ],
      paths: const ['/home', '/fleet', '/geofences', '/profile'],
      centerPath: '/fleet/flights',
      center: NavCenterAction(
        icon: Icons.near_me_rounded,
        label: 'Vuelos en curso',
        badge: flying,
        onPressed: () => context.go('/fleet/flights'),
      ),
    );
  }

  static RoleTabs _admin(BuildContext context) => RoleTabs(
    destinations: const [
      NavDestination(icon: Icons.insights_rounded, label: 'Resumen'),
      NavDestination(icon: Icons.home_work_outlined, label: 'Centrales'),
      NavDestination(icon: Icons.badge_outlined, label: 'Cuentas'),
      _profile,
    ],
    paths: const ['/home', '/hubs', '/users', '/profile'],
    center: NavCenterAction(
      icon: Icons.add_rounded,
      label: 'Crear central o cuenta',
      onPressed: () => showAdminCreateSheet(context),
    ),
  );
}
