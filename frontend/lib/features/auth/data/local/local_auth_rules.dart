import '../../../../core/api_exception.dart';

/// Reglas de normalización y errores del repositorio local. Comparte el
/// formato de mensaje con Nest para que la UI muestre lo mismo en los dos
/// orígenes de datos.
class LocalAuthRules {
  LocalAuthRules._();

  static const String otp = '123456';
  static const String tokenPrefix = 'local-session:';
  static const String resetMessage = 'Si el contacto existe, te enviaremos un código.';

  static String? normalizeEmail(String? value) {
    final email = value?.trim().toLowerCase();
    return email == null || email.isEmpty ? null : email;
  }

  static String? normalizePhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\D'), '');
    return phone == null || phone.isEmpty ? null : phone;
  }

  static ApiException invalidOtp() =>
      ApiException('El código es inválido o ya venció.', statusCode: 400);

  static ApiException expiredSession() => ApiException(
    'Tu sesión expiró. Inicia sesión de nuevo.',
    statusCode: 401,
  );

  static ApiException duplicateContact() => ApiException(
    'Ya existe una cuenta con este correo o celular.',
    statusCode: 409,
  );
}