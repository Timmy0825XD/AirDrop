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
