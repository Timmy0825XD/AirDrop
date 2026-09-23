import 'package:go_router/go_router.dart';

import 'placeholder_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, _) => '/login',
    ),
    GoRoute(
      path: '/login',
      builder: (_, _) =>
          const PlaceholderScreen(title: 'Ingresar', note: 'La pantalla de login llega en la Fase 2.'),
    ),
    GoRoute(
      path: '/register',
      builder: (_, _) =>
          const PlaceholderScreen(title: 'Registro', note: 'La pantalla de registro llega en la Fase 2.'),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (_, _) =>
          const PlaceholderScreen(title: 'Recuperar contraseña', note: 'Llega en la Fase 2.'),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (_, _) =>
          const PlaceholderScreen(title: 'Restablecer contraseña', note: 'Llega en la Fase 2.'),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (_, _) =>
          const PlaceholderScreen(title: 'Código de verificación', note: 'Llega en la Fase 2.'),
    ),
    GoRoute(
      path: '/unauthorized',
      builder: (_, _) => const PlaceholderScreen(
          title: 'Sin permiso', note: 'No tienes permiso para ver esa pantalla.'),
    ),
    GoRoute(
      path: '/home',
      builder: (_, _) =>
          const PlaceholderScreen(title: 'Inicio', note: 'El home por rol llega en la Fase 3.'),
    ),
  ],
  errorBuilder: (_, _) => const PlaceholderScreen(
      title: 'No encontrada', note: 'Esa pantalla no existe.'),
);
