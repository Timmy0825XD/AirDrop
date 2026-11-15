import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../data/app_settings.dart';

/// Aplica los ajustes a todo lo que hay debajo (RF-52): el tamaño del
/// texto se suma al del teléfono, "reducir movimiento" vale aunque el
/// teléfono no lo pida y el modo sencillo agranda los botones. Va en el
/// `builder` de la app, así ninguna pantalla tiene que saber de ajustes:
/// todas leen `MediaQuery` y `Theme` como siempre.
class SettingsScope extends ConsumerWidget {
  const SettingsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final media = MediaQuery.of(context);
    // El tamaño del teléfono, medido sobre un texto de 16.
    final system = media.textScaler.scale(16) / 16;
    final scoped = MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(system * settings.textSize.factor),
        disableAnimations: media.disableAnimations || settings.reduceMotion,
      ),
      child: child,
    );
    if (!settings.simpleMode) return scoped;
    return Theme(data: AppTheme.roomy(Theme.of(context)), child: scoped);
  }
}

/// El tema claro y el oscuro que tocan con los ajustes: los de siempre o
/// los de alto contraste.
({ThemeData light, ThemeData dark}) themesFor(AppSettings settings) =>
    settings.highContrast
    ? (light: AppTheme.lightHighContrast, dark: AppTheme.darkHighContrast)
    : (light: AppTheme.light, dark: AppTheme.dark);
