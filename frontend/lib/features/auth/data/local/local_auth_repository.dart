import '../../../../core/api_exception.dart';
import '../../../../core/auth/token_store.dart';
import '../auth_models.dart';
import '../auth_repository.dart';
import 'local_auth_rules.dart';
import 'local_fixtures.dart';
import 'local_user.dart';

/// Sesión simulada en memoria, para trabajar sin NestJS. Aplica las
/// mismas reglas que el backend para que los mensajes coincidan.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({TokenStore? tokenStore})
    : _tokenStore = tokenStore ?? TokenStore(),
      _users = {for (final user in localFixtureUsers) user.id: user.copy()};

  final TokenStore _tokenStore;
  final Map<String, LocalUser> _users;

  /// Alta pública: siempre nace un solicitante, porque el despachador y el
  /// operador los crea el administrador.
  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    final phone = LocalAuthRules.normalizePhone(request.phone);
    if (phone == null) {
      throw ApiException(
        'El celular debe tener exactamente 10 dígitos (Colombia).',
        statusCode: 400,
      );
    }
    final email = LocalAuthRules.normalizeEmail(request.email);
    if (email == null) {
      throw const ApiException('El correo es obligatorio.', statusCode: 400);
    }
    final documentNumber = LocalAuthRules.normalizeDocument(
      request.documentType,
      request.documentNumber,
    );
    if (documentNumber == null) {
      throw ApiException(LocalAuthRules.invalidDocument, statusCode: 400);
    }
    if (_contactTaken(email, phone)) throw LocalAuthRules.duplicateContact();
    if (_documentTaken(request.documentType, documentNumber)) {
      throw LocalAuthRules.duplicateDocument();
    }

    final id = 'local-${DateTime.now().microsecondsSinceEpoch}';
    _users[id] = LocalUser(
      id: id,
      fullName: request.fullName.trim(),
      email: email,
      phone: phone,
      documentType: request.documentType,
      documentNumber: documentNumber,
      role: UserRole.requester,
      status: UserStatus.unverified,
      password: request.password,
    );
    return RegisterResponse(
      message: 'Cuenta creada. Verifica el código para activarla.',
      userId: id,
    );
  }

  @override
  Future<AuthSession> verifyOtp(VerifyOtpRequest request) async {
    final user = _requireUser(request.contact);
    if (user.status != UserStatus.unverified ||
        request.code != LocalAuthRules.otp) {
      throw LocalAuthRules.invalidOtp();
    }
    user.status = UserStatus.active;
    return _sessionFor(user);
  }

  @override
  Future<AuthMessage> resendOtp(ResendOtpRequest request) async {
    _requireUser(request.contact);
    return const AuthMessage(message: LocalAuthRules.resetMessage);
  }

  @override
  Future<AuthSession> login(LoginRequest request) async {
    final user = _findByContact(request.contact);
    if (user == null || user.password != request.password) {
      throw ApiException(
        'El correo y la contraseña no coinciden.',
        statusCode: 401,
      );
    }
    final blocked = _loginBlock(user.status);
    if (blocked != null) throw blocked;
    return _sessionFor(user);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthMessage> forgotPassword(ForgotPasswordRequest request) async {
    return const AuthMessage(message: LocalAuthRules.resetMessage);
  }

  @override
  Future<AuthMessage> resetPassword(ResetPasswordRequest request) async {
    final user = _findByContact(request.contact);
    if (user == null || request.code != LocalAuthRules.otp) {
      throw ApiException(LocalAuthRules.resetMessage, statusCode: 400);
    }
    user.password = request.password;
    return const AuthMessage(
      message: 'La contraseña se actualizó. Ya puedes iniciar sesión.',
    );
  }

  @override
  Future<PublicUser> me() async {
    return (await _requireSessionUser()).toPublicUser();
  }

  /// El documento se edita solo para el solicitante y siempre van juntos
  /// tipo y número. Es el mismo orden de reglas que en Nest.
  @override
  Future<PublicUser> updateProfile(UpdateProfileRequest request) async {
    final user = await _requireSessionUser();
    _assertSomethingToUpdate(request);
    if (request.fullName != null) _applyFullName(user, request.fullName!);
    if (request.email != null) _applyEmail(user, request.email!);
    if (request.phone != null) _applyPhone(user, request.phone!);
    if (request.documentType != null || request.documentNumber != null) {
      _applyDocument(user, request);
    }
    return user.toPublicUser();
  }

  void _assertSomethingToUpdate(UpdateProfileRequest request) {
    final empty =
        request.fullName == null &&
        request.email == null &&
        request.phone == null &&
        request.documentType == null &&
        request.documentNumber == null;
    if (empty) {
      throw ApiException(
        'Debes enviar al menos un campo para actualizar.',
        statusCode: 400,
      );
    }
  }

  void _applyFullName(LocalUser user, String raw) {
    final fullName = raw.trim();
    if (fullName.isEmpty) {
      throw ApiException('El nombre es obligatorio.', statusCode: 400);
    }
    user.fullName = fullName;
  }

  void _applyEmail(LocalUser user, String raw) {
    final email = LocalAuthRules.normalizeEmail(raw);
    if (email == null || _emailTaken(email, user.id)) {
      throw LocalAuthRules.duplicateContact();
    }
    user.email = email;
  }

  void _applyPhone(LocalUser user, String raw) {
    final phone = LocalAuthRules.normalizePhone(raw);
    if (phone == null || _phoneTaken(phone, user.id)) {
      throw LocalAuthRules.duplicateContact();
    }
    user.phone = phone;
  }

  void _applyDocument(LocalUser user, UpdateProfileRequest request) {
    if (user.role != UserRole.requester) {
      throw LocalAuthRules.documentOnlyForRequester();
    }
    if (request.documentType == null || request.documentNumber == null) {
      throw LocalAuthRules.documentTogether();
    }
    final type = request.documentType!;
    final documentNumber = LocalAuthRules.normalizeDocument(
      type,
      request.documentNumber,
    );
    if (documentNumber == null) {
      throw ApiException(LocalAuthRules.invalidDocument, statusCode: 400);
    }
    if (_documentTaken(type, documentNumber, exceptId: user.id)) {
      throw LocalAuthRules.duplicateDocument();
    }
    user.documentType = type;
    user.documentNumber = documentNumber;
  }

  ApiException? _loginBlock(UserStatus status) => switch (status) {
    UserStatus.unverified => const ApiException(
      'Debes verificar tu cuenta. Te enviamos un código nuevo a tu correo.',
      statusCode: 403,
      code: 'account_unverified',
    ),
    UserStatus.locked => ApiException(
      'Demasiados intentos. Intenta de nuevo en unos minutos.',
      statusCode: 403,
    ),
    UserStatus.suspended => ApiException(
      'Tu cuenta está suspendida. Habla con el administrador.',
      statusCode: 403,
    ),
    UserStatus.active => null,
  };

  LocalUser _requireUser(AuthContact contact) {
    final user = _findByContact(contact);
    if (user == null) throw LocalAuthRules.invalidOtp();
    return user;
  }

  Future<LocalUser> _requireSessionUser() async {
    final token = await _tokenStore.read();
    if (token == null || !token.startsWith(LocalAuthRules.tokenPrefix)) {
      throw LocalAuthRules.expiredSession();
    }
    final user = _users[token.substring(LocalAuthRules.tokenPrefix.length)];
    if (user == null) throw LocalAuthRules.expiredSession();
    return user;
  }

  LocalUser? _findByContact(AuthContact contact) {
    final email = LocalAuthRules.normalizeEmail(contact.email);
    final phone = LocalAuthRules.normalizePhone(contact.phone);
    for (final user in _users.values) {
      if (email != null && user.email == email) return user;
      if (phone != null && user.phone == phone) return user;
    }
    return null;
  }

  bool _emailTaken(String email, String currentId) =>
      _users.values.any((user) => user.id != currentId && user.email == email);

  bool _phoneTaken(String phone, String currentId) =>
      _users.values.any((user) => user.id != currentId && user.phone == phone);

  bool _contactTaken(String? email, String phone) {
    if (email != null && _emailTaken(email, '')) return true;
    return _phoneTaken(phone, '');
  }

  /// El documento es único por tipo: dos cédulas de ciudadanía distintas
  /// pueden compartir número si cambia el tipo.
  bool _documentTaken(
    DocumentType type,
    String documentNumber, {
    String? exceptId,
  }) {
    return _users.values.any(
      (user) =>
          user.id != exceptId &&
          user.documentType == type &&
          user.documentNumber == documentNumber,
    );
  }

  AuthSession _sessionFor(LocalUser user) => AuthSession(
    accessToken: '${LocalAuthRules.tokenPrefix}${user.id}',
    user: user.toPublicUser(),
  );
}
