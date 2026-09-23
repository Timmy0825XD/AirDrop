import 'field_limits.dart';

/// Reglas de validación de los formularios. Cada método devuelve `null`
/// si el valor es válido o el mensaje (español) a mostrar. Todos los
/// topes salen de [FieldLimits], así el front coincide con Nest y no se
/// gastan peticiones que iban a terminar en 400.
class Validators {
  Validators._();

  static final RegExp _emailPattern =
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu nombre.';
    if (text.length > FieldLimits.fullName) {
      return 'El nombre no puede superar ${FieldLimits.fullName} caracteres.';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu correo.';
    if (text.length > FieldLimits.email) {
      return 'El correo no puede superar ${FieldLimits.email} caracteres.';
    }
    if (!_emailPattern.hasMatch(text)) return 'Escribe un correo válido.';
    return null;
  }

  static String? phone(String? value) {
    // Quita espacios, puntos y símbolos igual que Nest antes de validar.
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.isEmpty) return 'Escribe tu celular.';
    if (!FieldLimits.phoneRegex.hasMatch(digits)) {
      return 'El celular debe tener ${FieldLimits.phoneDigits} dígitos.';
    }
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Escribe tu contraseña.';
    if (text.length < FieldLimits.passwordMin) {
      return 'La contraseña debe tener al menos ${FieldLimits.passwordMin} caracteres.';
    }
    if (text.length > FieldLimits.passwordMax) {
      return 'La contraseña no puede superar ${FieldLimits.passwordMax} caracteres.';
    }
    return null;
  }

  static String? otp(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe el código.';
    if (!RegExp(r'^\d{6}$').hasMatch(text)) {
      return 'El código debe tener ${FieldLimits.otpDigits} dígitos.';
    }
    return null;
  }
}
