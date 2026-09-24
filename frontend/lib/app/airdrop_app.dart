import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'providers.dart';
import 'router.dart';

class AirDropApp extends ConsumerStatefulWidget {
  const AirDropApp({super.key});

  @override
  ConsumerState<AirDropApp> createState() => _AirDropAppState();
}

class _AirDropAppState extends ConsumerState<AirDropApp> {
  @override
  void initState() {
    super.initState();
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
