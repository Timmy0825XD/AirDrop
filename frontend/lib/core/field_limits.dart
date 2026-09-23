class FieldLimits {
  FieldLimits._();

  static const int fullName = 40;
  static const int email = 50;
  static const int phoneDigits = 10;
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

  static final RegExp phoneRegex = RegExp(r'^\d{10}$');
}