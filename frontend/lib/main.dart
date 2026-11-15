import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/airdrop_app.dart';
import 'app/provider_retry.dart';
import 'core/prefs/app_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Las preferencias del teléfono se abren antes del primer cuadro.
  final prefs = await loadPrefs();
  runApp(
    ProviderScope(
      retry: retryOnlyWithoutResponse,
      overrides: [prefsStoreProvider.overrideWithValue(prefs)],
      child: const AirDropApp(),
    ),
  );
}
