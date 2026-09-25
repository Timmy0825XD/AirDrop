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
import 'placeholder_screen.dart';

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
