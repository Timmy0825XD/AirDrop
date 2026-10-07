import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_models.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/presentation/verify_otp_screen.dart';
import '../features/fleet/presentation/drone_form_screen.dart';
import '../features/fleet/presentation/fleet_screen.dart';
import '../features/geofences/presentation/geofence_form_screen.dart';
import '../features/geofences/presentation/geofences_screen.dart';
import '../features/home/presentation/role_home.dart';
import '../features/hubs/presentation/hub_detail_screen.dart';
import '../features/hubs/presentation/hub_form_screen.dart';
import '../features/hubs/presentation/hubs_screen.dart';
import '../features/inventory/presentation/inventory_form_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/orders/presentation/emergency_screen.dart';
import '../features/orders/presentation/hub_emergency_screen.dart';
import '../features/orders/presentation/hub_plan_form_screen.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/orders/presentation/order_history_screen.dart';
import '../features/orders/presentation/plan_detail_screen.dart';
import '../features/orders/presentation/plan_form_screen.dart';
import '../features/orders/presentation/plans_screen.dart';
import '../features/orders/presentation/queue_screen.dart';
import '../features/orders/presentation/scheduled_screen.dart';
import '../features/users/presentation/user_form_screen.dart';
import '../features/users/presentation/users_screen.dart';
import 'placeholder_screen.dart';

/// Roles que autorizan cada ruta protegida por rol. Varias rutas de pedidos
/// admiten solicitante y despachador. Cualquier otra cuenta recibe
/// `/unauthorized`. `null` = solo hace falta sesión.
const _roleRoutes = <String, Set<UserRole>>{
  '/hubs': {UserRole.admin},
  '/hubs/new': {UserRole.admin},
  '/hubs/me': {UserRole.dispatcher},
  '/users': {UserRole.admin},
  '/users/new': {UserRole.admin},
  '/inventory': {UserRole.dispatcher},
  '/inventory/new': {UserRole.dispatcher},
  '/inventory/:id': {UserRole.dispatcher},
  '/fleet': {UserRole.fleetOperator},
  '/fleet/new': {UserRole.fleetOperator},
  '/geofences': {UserRole.fleetOperator},
  '/geofences/new': {UserRole.fleetOperator},
  '/geofences/:id': {UserRole.fleetOperator},
  '/orders/emergency': {UserRole.requester},
  '/orders/plans/new': {UserRole.requester},
  '/orders/plans': {UserRole.requester, UserRole.dispatcher},
  '/orders/mine': {UserRole.requester},
  '/orders/queue': {UserRole.dispatcher},
  '/orders/scheduled': {UserRole.dispatcher},
  '/orders/hub-emergency': {UserRole.dispatcher},
  '/orders/hub-plans/new': {UserRole.dispatcher},
  '/orders/plans/:id': {UserRole.requester, UserRole.dispatcher},
  '/orders/:id': {UserRole.requester, UserRole.dispatcher},
};

const _fixedOrderRoutes = {
  'emergency',
  'mine',
  'queue',
  'scheduled',
  'hub-emergency',
  'plans',
};

/// Rol que exige una ruta con parámetro. Las rutas fijas se resuelven
/// primero en el `redirect`; este camino cubre `/inventory/<id>`,
/// `/geofences/<id>`, `/orders/<id>` y `/orders/plans/<id>`.
Set<UserRole>? _parameterizedRole(String location) {
  final segments = location.split('/');
  if (segments.length == 3 && segments[2].isNotEmpty) {
    return switch (segments[1]) {
      'inventory' => _roleRoutes['/inventory/:id'],
      'geofences' => _roleRoutes['/geofences/:id'],
      'orders' when !_fixedOrderRoutes.contains(segments[2]) =>
        _roleRoutes['/orders/:id'],
      _ => null,
    };
  }
  if (segments.length == 4 &&
      segments[1] == 'orders' &&
      segments[2] == 'plans' &&
      segments[3].isNotEmpty &&
      segments[3] != 'new') {
    return _roleRoutes['/orders/plans/:id'];
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/login',
    redirect: (_, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) return null;

      final isAuthenticated = auth.asData?.value.isAuthenticated ?? false;
      final location = state.matchedLocation;
      const publicLocations = {
        '/login',
        '/register',
        '/forgot-password',
        '/reset-password',
        '/verify-otp',
      };

      if (location == '/') return isAuthenticated ? '/home' : '/login';
      if (!isAuthenticated && !publicLocations.contains(location)) {
        return '/login';
      }
      if (isAuthenticated && publicLocations.contains(location)) {
        return '/home';
      }

      // Guardia por rol: fuera del rol autorizado, a /unauthorized.
      final requiredRoles =
          _roleRoutes[location] ?? _parameterizedRole(location);
      if (requiredRoles != null) {
        final user = auth.asData?.value.user;
        if (user == null || !requiredRoles.contains(user.role)) {
          return '/unauthorized';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/login'),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          contact: state.extra is AuthContact
              ? state.extra as AuthContact
              : null,
        ),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (_, state) => VerifyOtpScreen(
          contact: state.extra is AuthContact
              ? state.extra as AuthContact
              : null,
        ),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/unauthorized',
        builder: (_, _) => const PlaceholderScreen(
          title: 'Sin permiso',
          note: 'No tienes permiso para ver esa pantalla.',
        ),
      ),
      GoRoute(path: '/home', builder: (_, _) => const RoleHomeScreen()),
      GoRoute(path: '/hubs', builder: (_, _) => const HubsScreen()),
      GoRoute(path: '/hubs/new', builder: (_, _) => const HubFormScreen()),
      GoRoute(path: '/hubs/me', builder: (_, _) => const HubDetailScreen()),
      GoRoute(path: '/users', builder: (_, _) => const UsersScreen()),
      GoRoute(path: '/users/new', builder: (_, _) => const UserFormScreen()),
      GoRoute(path: '/inventory', builder: (_, _) => const InventoryScreen()),
      GoRoute(
        path: '/inventory/new',
        builder: (_, _) => const InventoryFormScreen(),
      ),
      GoRoute(
        path: '/inventory/:id',
        builder: (_, state) =>
            InventoryFormScreen(itemId: state.pathParameters['id']),
      ),
      GoRoute(path: '/fleet', builder: (_, _) => const FleetScreen()),
      GoRoute(path: '/fleet/new', builder: (_, _) => const DroneFormScreen()),
      GoRoute(path: '/geofences', builder: (_, _) => const GeofencesScreen()),
      GoRoute(
        path: '/geofences/new',
        builder: (_, _) => const GeofenceFormScreen(),
      ),
      GoRoute(
        path: '/geofences/:id',
        builder: (_, state) =>
            GeofenceFormScreen(geofenceId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/orders/emergency',
        builder: (_, _) => const EmergencyScreen(),
      ),
      GoRoute(
        path: '/orders/plans/new',
        builder: (_, _) => const PlanFormScreen(),
      ),
      GoRoute(path: '/orders/plans', builder: (_, _) => const PlansScreen()),
      GoRoute(
        path: '/orders/plans/:id',
        builder: (_, state) =>
            PlanDetailScreen(planId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/orders/mine',
        builder: (_, _) => const OrderHistoryScreen(),
      ),
      GoRoute(path: '/orders/queue', builder: (_, _) => const QueueScreen()),
      GoRoute(
        path: '/orders/scheduled',
        builder: (_, _) => const ScheduledScreen(),
      ),
      GoRoute(
        path: '/orders/hub-emergency',
        builder: (_, _) => const HubEmergencyScreen(),
      ),
      GoRoute(
        path: '/orders/hub-plans/new',
        builder: (_, _) => const HubPlanFormScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id'] ?? ''),
      ),
    ],
    errorBuilder: (_, _) => const PlaceholderScreen(
      title: 'No encontrada',
      note: 'Esa pantalla no existe.',
    ),
  );

  ref.listen(authControllerProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
