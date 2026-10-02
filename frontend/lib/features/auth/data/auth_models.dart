import '../../../core/colombian_phone.dart';

/// Documento de identidad del solicitante. Los mismos tres valores de
/// `backend/src/common/enums/document-type.enum.ts`. Solo el solicitante
/// lo tiene: el administrador crea a las cuentas institucionales sin
/// documento.
enum DocumentType {
  citizenshipId('citizenship_id'),
  foreignerId('foreigner_id'),
  ppt('ppt');

  const DocumentType(this.apiValue);

  final String apiValue;

  static DocumentType fromJson(String value) {
    return DocumentType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () =>
          throw FormatException('Tipo de documento desconocido: $value'),
    );
  }
}

enum UserRole {
  requester('requester'),
  dispatcher('dispatcher'),
  fleetOperator('fleet_operator'),
  admin('admin');

  const UserRole(this.apiValue);

  final String apiValue;

  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (role) => role.apiValue == value,
      orElse: () => throw FormatException('Rol de usuario desconocido: $value'),
    );
  }
}

enum UserStatus {
  unverified('unverified'),
  active('active'),
  locked('locked'),
  suspended('suspended');

  const UserStatus(this.apiValue);

  final String apiValue;

  static UserStatus fromJson(String value) {
    return UserStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () =>
          throw FormatException('Estado de usuario desconocido: $value'),
    );
  }
}

class PublicUser {
  const PublicUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.hubIds,
    this.documentType,
    this.documentNumber,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    return PublicUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      documentType: _documentTypeFrom(json['documentType']),
      documentNumber: json['documentNumber'] as String?,
      role: UserRole.fromJson(json['role'] as String),
      status: UserStatus.fromJson(json['status'] as String),
      hubIds: _hubIdsFrom(json['hubIds']),
    );
  }

  final String id;
  final String fullName;
  final String? email;
  final String? phone;

  /// Solo el solicitante registra documento; las cuentas institucionales
  /// nacen sin él.
  final DocumentType? documentType;
  final String? documentNumber;

  final UserRole role;
  final UserStatus status;

  /// Centrales asignadas: exactamente una para el despachador, una o más
  /// para el operador de flota, ninguna para el solicitante y el
  /// administrador. Un despachador u operador nunca trae `hubId` en el JSON.
  final List<String> hubIds;

  bool get isRequester => role == UserRole.requester;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'documentType': documentType?.apiValue,
      'documentNumber': documentNumber,
      'role': role.apiValue,
      'status': status.apiValue,
      'hubIds': hubIds,
    };
  }

  static DocumentType? _documentTypeFrom(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DocumentType.fromJson(value);
  }

  /// Lee la lista de centrales sin fallar cuando el backend omite el
  /// campo: "ninguna asignada" es un caso normal, no un error.
  static List<String> _hubIdsFrom(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }
}

class AuthContact {
  const AuthContact._({this.email, this.phone});

  const AuthContact.email(String email) : this._(email: email);

  const AuthContact.phone(String phone) : this._(phone: phone);

  /// Convierte el campo único del login en correo o celular.
  /// El celular se normaliza a 10 dígitos como lo espera Nest, así que
  /// escribir `+57 300 123 4567` funciona igual que `300 123 4567`.
  factory AuthContact.parse(String raw) {
    final value = raw.trim();
    final looksLikeEmail = RegExp(r'[A-Za-z@]').hasMatch(value);
    if (looksLikeEmail) {
      return AuthContact.email(value.toLowerCase());
    }
    return AuthContact.phone(normalizeColombianPhone(value));
  }

  final String? email;
  final String? phone;

  Map<String, dynamic> toJson() {
    return email != null ? {'email': email} : {'phone': phone};
  }
}

class LoginRequest {
  const LoginRequest({required this.contact, required this.password});

  final AuthContact contact;
  final String password;

  Map<String, dynamic> toJson() {
    return {...contact.toJson(), 'password': password};
  }
}

/// Alta pública del solicitante. No lleva `role`: Nest lo fija en
/// `requester` y el `ValidationPipe` rechaza el campo con
/// `forbidNonWhitelisted`. El celular es obligatorio porque el código de
/// un uso va al celular; el correo es opcional.
class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.documentType,
    required this.documentNumber,
    required this.phone,
    required this.password,
    required this.consentAccepted,
    this.email,
  });

  final String fullName;
  final DocumentType documentType;
  final String documentNumber;
  final String phone;
  final String password;
  final bool consentAccepted;
  final String? email;

  Map<String, dynamic> toJson() {
    return {
      if (email != null) 'email': email,
      'fullName': fullName,
      'documentType': documentType.apiValue,
      'documentNumber': documentNumber,
      'phone': phone,
      'password': password,
      'consentAccepted': consentAccepted,
    };
  }
}

class RegisterResponse {
  const RegisterResponse({required this.message, required this.userId});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'] as String,
      userId: json['userId'] as String,
    );
  }

  final String message;
  final String userId;
}

class VerifyOtpRequest {
  const VerifyOtpRequest({required this.contact, required this.code});

  final AuthContact contact;
  final String code;

  Map<String, dynamic> toJson() {
    return {...contact.toJson(), 'code': code};
  }
}

class ResendOtpRequest {
  const ResendOtpRequest({required this.contact});

  final AuthContact contact;

  Map<String, dynamic> toJson() => contact.toJson();
}

class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.contact});

  final AuthContact contact;

  Map<String, dynamic> toJson() => contact.toJson();
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.contact,
    required this.code,
    required this.password,
  });

  final AuthContact contact;
  final String code;
  final String password;

  Map<String, dynamic> toJson() {
    return {...contact.toJson(), 'code': code, 'password': password};
  }
}

/// Edición de perfil. `documentType` y `documentNumber` solo aplican al
/// solicitante y Nest los exige juntos: enviar uno solo devuelve "El tipo
/// y el número de documento se actualizan juntos".
class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.fullName,
    this.email,
    this.phone,
    this.documentType,
    this.documentNumber,
  });

  final String? fullName;
  final String? email;
  final String? phone;
  final DocumentType? documentType;
  final String? documentNumber;

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (documentType != null) 'documentType': documentType!.apiValue,
      if (documentNumber != null) 'documentNumber': documentNumber,
    };
  }
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      user: PublicUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final PublicUser user;
}

class AuthMessage {
  const AuthMessage({required this.message});

  factory AuthMessage.fromJson(Map<String, dynamic> json) {
    return AuthMessage(message: json['message'] as String);
  }

  final String message;
}
