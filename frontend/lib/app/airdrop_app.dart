import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'providers.dart';
import 'router.dart';

/// Raíz de la app: tema (claro/oscuro según el sistema), rutas,
/// interface de Material en español y conexión de la sesión.
class AirDropApp extends ConsumerStatefulWidget {
  const AirDropApp({super.key});

  @override
  ConsumerState<AirDropApp> createState() => _AirDropAppState();
}

class _AirDropAppState extends ConsumerState<AirDropApp> {
  @override
  void initState() {
    super.initState();
    // Contrato del ApiClient (Opción A): 401 con token → borrar sesión
    // y volver al login desde cualquier pantalla.
    ref.read(apiClientProvider).onUnauthorized = () => appRouter.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AirDrop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
