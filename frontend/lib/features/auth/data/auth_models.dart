enum UserRole {
  requester('requester'),
  dispatcher('dispatcher'),
  fleetOperator('fleet_operator'),
  admin('admin');

  const UserRole(this.apiValue);

  final String apiValue;

  bool get canSelfRegister => this != UserRole.admin;

  /// Estos roles requieren un correo según el contrato de NestJS.
  bool get requiresEmail =>
      this == UserRole.dispatcher || this == UserRole.fleetOperator;

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
    required this.hubId,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    return PublicUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: UserRole.fromJson(json['role'] as String),
      status: UserStatus.fromJson(json['status'] as String),
      hubId: json['hubId'] as String?,
    );
  }

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final UserRole role;
  final UserStatus status;
  final String? hubId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.apiValue,
      'status': status.apiValue,
      'hubId': hubId,
    };
  }
}

class AuthContact {
  const AuthContact._({this.email, this.phone});

  const AuthContact.email(String email) : this._(email: email);

  const AuthContact.phone(String phone) : this._(phone: phone);

  /// Convierte el campo único del login en correo o celular.
  /// Los signos de téléphone se limpian como lo hace NestJS.
  factory AuthContact.parse(String raw) {
    final value = raw.trim();
    final looksLikeEmail = RegExp(r'[A-Za-z@]').hasMatch(value);
    if (looksLikeEmail) {
      return AuthContact.email(value.toLowerCase());
    }
    return AuthContact.phone(value.replaceAll(RegExp(r'\D'), ''));
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

class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    this.email,
    this.phone,
    required this.password,
    required this.role,
    required this.consentAccepted,
  });

  final String fullName;
  final String? email;
  final String? phone;
  final String password;
  final UserRole role;
  final bool consentAccepted;

  Map<String, dynamic> toJson() {
    return {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'fullName': fullName,
      'password': password,
      'role': role.apiValue,
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

class UpdateProfileRequest {
  const UpdateProfileRequest({this.fullName, this.email, this.phone});

  final String? fullName;
  final String? email;
  final String? phone;

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
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
