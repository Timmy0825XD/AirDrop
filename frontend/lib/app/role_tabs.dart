import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_tab_bar.dart';
import '../theme/app_icons.dart';
import '../features/auth/data/auth_models.dart';
import '../features/home/presentation/widgets/admin/admin_create_sheet.dart';
import '../features/fleet/data/fleet_providers.dart';
import '../features/hubs/data/hub_providers.dart';
import '../features/orders/data/order_providers.dart';
import '../features/orders/data/queue_live.dart';
import '../features/settings/data/app_settings.dart';

/// Los destinos de la barra de cada rol y su acción del centro.
///
/// - Solicitante: Inicio · Pedidos · (Pedir urgencia) · Planes · Perfil.
///   En modo sencillo: Inicio · Pedidos · Perfil.
/// - Despachador: Inicio · Agenda (las franjas del día) · (Cola de urgencias) ·
///   Inventario · Más. La cola también es destino: la abre el botón del centro.
/// - Operador: Inicio · Flota · (Vuelos en curso) · Geovallas · Perfil. El
///   botón abre el mapa de cada dron en misión; "Nuevo dron" está en Flota.
/// - Administrador: Resumen · Centrales · (Nueva) · Cuentas · Perfil.
class RoleTabs {
  const RoleTabs({
    required this.destinations,
    required this.paths,
    this.center,
    this.centerPath,
  });

  final List<NavDestination> destinations;
  final List<String> paths;

  /// La acción del centro; el modo sencillo no la tiene.
  final NavCenterAction? center;

  /// Ruta que abre el botón del centro cuando es un destino más.
  final String? centerPath;

  int? indexOf(String location) {
    final i = paths.indexOf(location);
    return i < 0 ? null : i;
  }

  /// La pantalla abierta es la de la pestaña del centro.
  bool isCenter(String location) => location == centerPath;

  bool isTab(String location) =>
      paths.contains(location) || location == centerPath;

  static RoleTabs of(UserRole role, BuildContext context, WidgetRef ref) =>
      switch (role) {
        UserRole.requester =>
          ref.watch(settingsProvider).simpleMode
              ? _simpleRequester
              : _requester(context),
        UserRole.dispatcher => _dispatcher(context, ref),
        UserRole.fleetOperator => _operator(context, ref),
        UserRole.admin => _admin(context),
      };

  static const _home = NavDestination(
    icon: Icons.space_dashboard_rounded,
    label: 'Inicio',
  );
  static const _profile = NavDestination(
    icon: Icons.person_outline_rounded,
    label: 'Perfil',
  );

  /// El modo sencillo (RF-52): tres destinos, siempre con su nombre.
  /// Pedir urgencia pasa a ser el botón grande del inicio.
  static const _simpleRequester = RoleTabs(
    destinations: [
      NavDestination(icon: AppIcons.home, label: 'Inicio'),
      NavDestination(icon: AppIcons.orders, label: 'Pedidos'),
      NavDestination(icon: AppIcons.profile, label: 'Perfil'),
    ],
    paths: ['/home', '/orders/mine', '/profile'],
  );

  static RoleTabs _requester(BuildContext context) => RoleTabs(
    destinations: const [
      NavDestination(icon: AppIcons.home, label: 'Inicio'),
      NavDestination(icon: AppIcons.orders, label: 'Pedidos'),
      NavDestination(icon: AppIcons.plans, label: 'Planes'),
      NavDestination(icon: AppIcons.profile, label: 'Perfil'),
    ],
    paths: const ['/home', '/orders/mine', '/orders/plans', '/profile'],
    center: NavCenterAction(
      icon: AppIcons.urgency,
      label: 'Pedir urgencia',
      tabLabel: 'Urgencia',
      onPressed: () => context.push('/orders/emergency'),
    ),
  );

  static RoleTabs _dispatcher(BuildContext context, WidgetRef ref) {
    final active = ref.watch(myHubProvider).value?.isActive ?? false;
    // La cola llega por socket (`queue-changed`) mientras la central opera.
    if (active) ref.watch(queueLiveProvider);
    final queue = active ? ref.watch(queueProvider).value?.length : null;
    return RoleTabs(
      destinations: const [
        NavDestination(icon: AppIcons.home, label: 'Inicio'),
        NavDestination(icon: AppIcons.calendar, label: 'Agenda'),
        NavDestination(icon: AppIcons.orders, label: 'Inventario'),
        NavDestination(icon: AppIcons.more, label: 'Más'),
      ],
      paths: const ['/home', '/orders/agenda', '/inventory', '/more'],
      centerPath: '/orders/queue',
      center: NavCenterAction(
        icon: AppIcons.urgency,
        label: 'Cola de urgencias',
        tabLabel: 'Urgencias',
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
        NavDestination(icon: Icons.hexagon_rounded, label: 'Geovallas'),
        _profile,
      ],
      paths: const ['/home', '/fleet', '/geofences', '/profile'],
      centerPath: '/fleet/flights',
      center: NavCenterAction(
        icon: Icons.radar_rounded,
        label: 'Mapa en vivo',
        tabLabel: 'Mapa',
        badge: flying,
        onPressed: () => context.go('/fleet/flights'),
      ),
    );
  }

  static RoleTabs _admin(BuildContext context) => RoleTabs(
    destinations: const [
      NavDestination(icon: Icons.insights_rounded, label: 'Resumen'),
      NavDestination(icon: Icons.home_work_rounded, label: 'Centrales'),
      NavDestination(icon: Icons.badge_rounded, label: 'Cuentas'),
      _profile,
    ],
    paths: const ['/home', '/hubs', '/users', '/profile'],
    center: NavCenterAction(
      icon: Icons.add_rounded,
      label: 'Crear central o cuenta',
      tabLabel: 'Crear',
      onPressed: () => showAdminCreateSheet(context),
    ),
  );
}
