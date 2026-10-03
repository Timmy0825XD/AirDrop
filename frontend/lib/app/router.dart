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
import '../features/home/presentation/role_home.dart';
import '../features/hubs/presentation/hub_detail_screen.dart';
import '../features/hubs/presentation/hub_form_screen.dart';
import '../features/hubs/presentation/hubs_screen.dart';
import '../features/users/presentation/user_form_screen.dart';
import '../features/users/presentation/users_screen.dart';
import 'placeholder_screen.dart';

/// Rol que autoriza cada ruta protegida por rol. Cualquier otra cuenta que
/// entre recibe `/unauthorized`. `null` = solo hace falta sesión.
const _roleRoutes = <String, UserRole>{
  '/hubs': UserRole.admin,
  '/hubs/new': UserRole.admin,
  '/hubs/me': UserRole.dispatcher,
  '/users': UserRole.admin,
  '/users/new': UserRole.admin,
};

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
      final requiredRole = _roleRoutes[location];
      if (requiredRole != null) {
        final user = auth.asData?.value.user;
        if (user == null || user.role != requiredRole) return '/unauthorized';
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
