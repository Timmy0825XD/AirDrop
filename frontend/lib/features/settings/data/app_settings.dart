import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/prefs/app_prefs.dart';

/// El tamaño del texto que elige la persona. Se suma al del teléfono.
enum TextSize {
  normal('Normal', 1),
  large('Grande', 1.15),
  extraLarge('Muy grande', 1.3);

  const TextSize(this.label, this.factor);

  final String label;
  final double factor;
}

/// Los ajustes de la app (RF-52). Son del teléfono, no de la cuenta: no
/// viajan al backend y siguen ahí al cerrar sesión.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textSize = TextSize.normal,
    this.highContrast = false,
    this.reduceMotion = false,
    this.simpleMode = false,
  });

  /// Claro, oscuro o automático (sigue al teléfono; es la opción inicial).
  final ThemeMode themeMode;
  final TextSize textSize;
  final bool highContrast;
  final bool reduceMotion;

  /// Solo del solicitante: una columna, botones grandes y tres destinos.
  final bool simpleMode;

  AppSettings copyWith({
    ThemeMode? themeMode,
    TextSize? textSize,
    bool? highContrast,
    bool? reduceMotion,
    bool? simpleMode,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    textSize: textSize ?? this.textSize,
    highContrast: highContrast ?? this.highContrast,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    simpleMode: simpleMode ?? this.simpleMode,
  );
}

/// Lee los ajustes guardados al arrancar y guarda cada cambio.
class SettingsController extends Notifier<AppSettings> {
  static const _theme = 'settings_theme';
  static const _text = 'settings_text_size';
  static const _contrast = 'settings_high_contrast';
  static const _motion = 'settings_reduce_motion';
  static const _simple = 'settings_simple_mode';

  PrefsStore get _prefs => ref.read(prefsStoreProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(prefsStoreProvider);
    T pick<T extends Enum>(List<T> values, String key, T fallback) {
      final name = prefs.getString(key);
      return values.where((v) => v.name == name).firstOrNull ?? fallback;
    }

    return AppSettings(
      themeMode: pick(ThemeMode.values, _theme, ThemeMode.system),
      textSize: pick(TextSize.values, _text, TextSize.normal),
      highContrast: prefs.getBool(_contrast) ?? false,
      reduceMotion: prefs.getBool(_motion) ?? false,
      simpleMode: prefs.getBool(_simple) ?? false,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setString(_theme, mode.name);
  }

  void setTextSize(TextSize size) {
    state = state.copyWith(textSize: size);
    _prefs.setString(_text, size.name);
  }

  void setHighContrast(bool on) {
    state = state.copyWith(highContrast: on);
    _prefs.setBool(_contrast, on);
  }

  void setReduceMotion(bool on) {
    state = state.copyWith(reduceMotion: on);
    _prefs.setBool(_motion, on);
  }

  void setSimpleMode(bool on) {
    state = state.copyWith(simpleMode: on);
    _prefs.setBool(_simple, on);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
