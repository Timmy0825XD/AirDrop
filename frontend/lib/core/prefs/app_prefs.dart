import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Las preferencias que viven en el teléfono y no en la cuenta: no viajan
/// al backend y siguen ahí al cerrar sesión (RF-52, RF-53). Solo guarda
/// cosas de la app (tema, tamaño del texto, si ya vio la bienvenida);
/// nunca datos de salud ni de la cuenta.
abstract class PrefsStore {
  /// `false` cuando no se pudo abrir el almacenamiento: la app funciona
  /// igual, pero nada de lo que se guarde sobrevive al cierre.
  bool get available;

  bool? getBool(String key);
  String? getString(String key);
  Future<void> setBool(String key, bool value);
  Future<void> setString(String key, String value);
}

/// Las preferencias de verdad, sobre `shared_preferences`.
class DevicePrefsStore implements PrefsStore {
  DevicePrefsStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  bool get available => true;

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}

/// Preferencias en memoria: el respaldo si el teléfono no deja abrir el
/// almacenamiento, y lo que usan las pruebas.
class MemoryPrefsStore implements PrefsStore {
  MemoryPrefsStore({this.available = false, Map<String, Object>? values})
    : _values = {...?values};

  final Map<String, Object> _values;

  @override
  final bool available;

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;
}

/// Abre las preferencias del teléfono antes de pintar la app, para que lo
/// guardado valga desde el primer cuadro. Si falla, sigue en memoria.
Future<PrefsStore> loadPrefs() async {
  try {
    return DevicePrefsStore(await SharedPreferences.getInstance());
  } catch (_) {
    return MemoryPrefsStore();
  }
}

/// Las preferencias de la app. `main` lo reemplaza con las del teléfono.
final prefsStoreProvider = Provider<PrefsStore>((ref) => MemoryPrefsStore());

/// Las llaves, en un solo lugar.
abstract final class PrefKeys {
  static const onboardingSeen = 'onboarding_seen';
}
