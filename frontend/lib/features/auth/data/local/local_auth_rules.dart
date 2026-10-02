import '../../../../core/api_exception.dart';
import '../../../../core/colombian_phone.dart';
import '../../../../core/field_limits.dart';
import '../auth_models.dart';

/// Reglas de normalización y errores del repositorio local. Comparte el
/// formato de mensaje con Nest para que la UI muestre lo mismo en los dos
/// orígenes de datos.
class LocalAuthRules {
  LocalAuthRules._();

  static const String otp = '123456';
  static const String tokenPrefix = 'local-session:';
  static const String resetMessage =
      'Si el contacto existe, te enviaremos un código.';

  /// Mismo texto que `Validators.invalidDocumentMessage` y que el
  /// `BadRequestException` de Nest en `auth.service.ts`.
  static const String invalidDocument =
      'El número de documento no corresponde a una cédula o a un PPT.';

  static String? normalizeEmail(String? value) {
    final email = value?.trim().toLowerCase();
    return email == null || email.isEmpty ? null : email;
  }

  static String? normalizePhone(String? value) {
    final phone = normalizeColombianPhone(value);
    return phone.isEmpty ? null : phone;
  }

  /// Mayúsculas y el patrón que corresponde al tipo, como
  /// `normalizeDocumentNumber` de Nest. Las dos cédulas son solo dígitos
  /// y el PPT admite letras. Devuelve `null` si no cumple.
  static String? normalizeDocument(DocumentType type, String? raw) {
    final value = (raw ?? '').trim().toUpperCase();
    final pattern = type == DocumentType.ppt
        ? FieldLimits.documentPptRegex
        : FieldLimits.documentDigitsRegex;
    return pattern.hasMatch(value) ? value : null;
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

  static ApiException duplicateDocument() =>
      ApiException('Ya existe una cuenta con este documento.', statusCode: 409);

  static ApiException documentOnlyForRequester() =>
      ApiException('El documento solo aplica al solicitante.', statusCode: 400);

  static ApiException documentTogether() => ApiException(
    'El tipo y el número de documento se actualizan juntos.',
    statusCode: 400,
  );
}
