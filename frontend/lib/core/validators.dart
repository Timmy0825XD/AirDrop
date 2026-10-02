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

  /// Cédula de ciudadanía o de extranjería: 6 a 10 dígitos.
  static String? documentDigits(String? value) {
    final digits = value?.trim() ?? '';
    if (digits.isEmpty) return 'Escribe el número de documento.';
    if (digits.length > FieldLimits.documentNumber) {
      return 'El número de documento no puede superar '
          '${FieldLimits.documentNumber} caracteres.';
    }
    if (!FieldLimits.documentDigitsRegex.hasMatch(digits)) {
      return invalidDocumentMessage;
    }
    return null;
  }

  /// PPT: 6 a 15 letras o números, en mayúsculas.
  static String? documentPpt(String? value) {
    final text = value?.trim().toUpperCase() ?? '';
    if (text.isEmpty) return 'Escribe el número de documento.';
    if (text.length > FieldLimits.documentNumber) {
      return 'El número de documento no puede superar '
          '${FieldLimits.documentNumber} caracteres.';
    }
    if (!FieldLimits.documentPptRegex.hasMatch(text)) {
      return invalidDocumentMessage;
    }
    return null;
  }

  /// Un único mensaje para los tres tipos de documento, igual que Nest.
  static const String invalidDocumentMessage =
      'El número de documento no corresponde a una cédula o a un PPT.';

  /// Lote del empaque. Nest lo pasa a mayúsculas antes de validar.
  static String? lotCode(String? value) {
    final text = value?.trim().toUpperCase() ?? '';
    if (text.isEmpty) return 'Escribe el lote.';
    if (!FieldLimits.lotCodeRegex.hasMatch(text)) {
      return 'El lote debe tener entre 3 y 20 letras, números o guiones.';
    }
    return null;
  }

  /// Fechas de vencimiento y fechas estimadas: AAAA-MM-DD.
  static String? isoDate(String? value, {String label = 'La fecha'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe $label.';
    if (!FieldLimits.isoDateRegex.hasMatch(text)) {
      return '$label debe ser AAAA-MM-DD.';
    }
    return null;
  }

  static String? latitude(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe la latitud.';
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < -90 || parsed > 90) {
      return 'La latitud no es válida.';
    }
    return null;
  }

  static String? longitude(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe la longitud.';
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < -180 || parsed > 180) {
      return 'La longitud no es válida.';
    }
    return null;
  }

  /// Motivo de geovalla o de mantenimiento.
  static String? reason(String? value, {bool required = true}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return required ? 'Escribe el motivo.' : null;
    }
    if (text.length > FieldLimits.reason) {
      return 'El motivo no puede superar ${FieldLimits.reason} caracteres.';
    }
    return null;
  }

  /// Identificador del dron en el campo.
  static String? droneIdentifier(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe el identificador.';
    if (text.length > FieldLimits.droneIdentifier) {
      return 'El identificador no puede superar '
          '${FieldLimits.droneIdentifier} caracteres.';
    }
    return null;
  }

  /// Nombre de central, medicamento o geovalla: mismo tope en Nest.
  static String? hubName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe el nombre.';
    if (text.length > FieldLimits.hubName) {
      return 'El nombre no puede superar ${FieldLimits.hubName} caracteres.';
    }
    return null;
  }

  static String? medicationName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe el nombre del medicamento.';
    if (text.length > FieldLimits.medicationName) {
      return 'El nombre no puede superar '
          '${FieldLimits.medicationName} caracteres.';
    }
    return null;
  }

  static String? geofenceName(String? value) => hubName(value);

  static String? address(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe la dirección.';
    if (text.length > FieldLimits.address) {
      return 'La dirección no puede superar '
          '${FieldLimits.address} caracteres.';
    }
    return null;
  }
}
