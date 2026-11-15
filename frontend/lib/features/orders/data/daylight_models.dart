/// Luz del día (RF-44). Contrato en `backend/src/airspace/`
/// (`GET /airspace/daylight`): de noche la norma no deja volar entregas.
library;

/// La salida y la puesta del sol del día simulado y si ahora se vuela.
class Daylight {
  const Daylight({
    required this.sunrise,
    required this.sunset,
    required this.daylight,
  });

  factory Daylight.fromJson(Map<String, dynamic> json) => Daylight(
    sunrise: DateTime.parse(json['sunrise'] as String),
    sunset: DateTime.parse(json['sunset'] as String),
    daylight: json['daylight'] == true,
  );

  final DateTime sunrise;
  final DateTime sunset;

  /// Es de día a la hora simulada: se puede volar.
  final bool daylight;
}

/// Para qué se abre una fórmula (RF-51). Cada apertura queda en el registro
/// de accesos con su propósito.
enum PrescriptionPurpose {
  /// La central todavía decide si autoriza.
  authorize('authorize', 'Autorizar'),

  /// Ya se autorizó: se consulta el histórico.
  history('history', 'Histórico'),

  /// Un reclamo (la app no tiene pantalla de reclamos; lo usa el registro).
  claim('claim', 'Reclamo');

  const PrescriptionPurpose(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PrescriptionPurpose? fromJson(Object? value) {
    for (final purpose in values) {
      if (purpose.apiValue == value) return purpose;
    }
    return null;
  }
}
