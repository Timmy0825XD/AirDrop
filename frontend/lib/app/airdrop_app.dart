import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../theme/app_theme.dart';
import 'providers.dart';
import 'router.dart';

class AirDropApp extends ConsumerStatefulWidget {
  const AirDropApp({super.key});

  @override
  ConsumerState<AirDropApp> createState() => _AirDropAppState();
}

class _AirDropAppState extends ConsumerState<AirDropApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = ref.read(routerProvider);
    ref.read(apiClientProvider).onUnauthorized = () {
      ref.read(authControllerProvider.notifier).clearSession();
      _router.go('/login');
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AirDrop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
