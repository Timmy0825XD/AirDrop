class FieldLimits {
  FieldLimits._();

  static const int fullName = 40;
  static const int email = 50;
  static const int phoneDigits = 10;

  /// Cédula (6–10) o PPT (hasta 15).
  static const int documentNumber = 15;

  static const int passwordMin = 8;
  static const int passwordMax = 72;
  static const int otpDigits = 6;
  static const int hubName = 80;
  static const int medicationName = 80;
  static const int geofenceName = 80;
  static const int droneModelName = 80;
  static const int address = 160;
  static const int reason = 160;
  static const int droneIdentifier = 32;
  static const int droneModelCode = 32;

  /// Código de lote del empaque.
  static const int lotCode = 20;

  static final RegExp phoneRegex = RegExp(r'^\d{10}$');

  /// Cédula de ciudadanía y de extranjería: solo dígitos.
  static final RegExp documentDigitsRegex = RegExp(r'^\d{6,10}$');

  /// PPT: letras y números, de 6 a 15.
  static final RegExp documentPptRegex = RegExp(r'^[A-Z0-9]{6,15}$');

  /// Lote del empaque: letras, números o guiones, de 3 a 20.
  static final RegExp lotCodeRegex = RegExp(r'^[A-Z0-9-]{3,20}$');

  /// Fechas en formato AAAA-MM-DD, sin horas.
  static final RegExp isoDateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
}