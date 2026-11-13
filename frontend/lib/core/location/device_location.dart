import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Dónde está el teléfono y con qué precisión (RU-02).
class LocationFix {
  const LocationFix({required this.point, required this.accuracyM});

  final LatLng point;

  /// Radio de error del GPS en metros.
  final double accuracyM;

  /// Con más de 50 m de error, el pin puede caer en la casa del vecino: se
  /// pide afinarlo en el mapa.
  bool get needsFineTuning => accuracyM > 50;
}

/// Por qué no se pudo leer la ubicación, con el texto para la persona.
class LocationProblem implements Exception {
  const LocationProblem(this.message, {this.fix});

  final String message;

  /// Qué ajuste abrir para arreglarlo, si hay uno.
  final PhoneSetting? fix;
}

/// El ajuste del teléfono que resuelve un [LocationProblem].
enum PhoneSetting { app, location }

/// Lee el GPS una vez, pidiendo el permiso si hace falta. Es una clase para
/// poder cambiarla en las pruebas (`deviceLocationProvider`).
class DeviceLocation {
  const DeviceLocation();

  Future<LocationFix> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationProblem(
        'La ubicación del teléfono está apagada. Enciéndela o marca el punto '
        'en el mapa.',
        fix: PhoneSetting.location,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationProblem(
        'Sin permiso de ubicación. Marca el punto en el mapa.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationProblem(
        'Le quitaste a AirDrop el permiso de ubicación. Actívalo en los '
        'ajustes o marca el punto en el mapa.',
        fix: PhoneSetting.app,
      );
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationFix(
        point: LatLng(position.latitude, position.longitude),
        accuracyM: position.accuracy,
      );
    } on Exception {
      throw const LocationProblem(
        'No pudimos leer tu ubicación. Intenta al aire libre o marca el '
        'punto en el mapa.',
      );
    }
  }

  /// Abre el ajuste que pide el problema.
  Future<void> openSettings(PhoneSetting which) async {
    switch (which) {
      case PhoneSetting.app:
        await Geolocator.openAppSettings();
      case PhoneSetting.location:
        await Geolocator.openLocationSettings();
    }
  }
}

final deviceLocationProvider = Provider<DeviceLocation>(
  (ref) => const DeviceLocation(),
);
