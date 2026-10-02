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

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    if (!request.role.canSelfRegister) {
      throw ApiException(
        'El rol no es válido para el registro.',
        statusCode: 400,
      );
    }

    final email = LocalAuthRules.normalizeEmail(request.email);
    final phone = LocalAuthRules.normalizePhone(request.phone);
    if (request.role.requiresEmail && email == null) {
      throw ApiException(
        'El despachador y el operador deben registrarse con correo institucional.',
        statusCode: 400,
      );
    }
    if (email == null && phone == null) {
      throw ApiException('Indica un correo o un celular.', statusCode: 400);
    }
    final duplicate = _users.values.any(
      (user) =>
          (email != null && user.email == email) ||
          (phone != null && user.phone == phone),
    );
    if (duplicate) throw LocalAuthRules.duplicateContact();

    final id = 'local-${DateTime.now().microsecondsSinceEpoch}';
    _users[id] = LocalUser(
      id: id,
      fullName: request.fullName.trim(),
      email: email,
      phone: phone,
      role: request.role,
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
        'Correo o celular y contraseña no coinciden.',
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

  @override
  Future<PublicUser> updateProfile(UpdateProfileRequest request) async {
    final user = await _requireSessionUser();
    if (request.fullName == null &&
        request.email == null &&
        request.phone == null) {
      throw ApiException(
        'Debes enviar al menos un campo para actualizar.',
        statusCode: 400,
      );
    }

    if (request.fullName != null) {
      final fullName = request.fullName!.trim();
      if (fullName.isEmpty) {
        throw ApiException('El nombre es obligatorio.', statusCode: 400);
      }
      user.fullName = fullName;
    }
    if (request.email != null) {
      final email = LocalAuthRules.normalizeEmail(request.email);
      if (email == null || _emailTaken(email, user.id)) {
        throw LocalAuthRules.duplicateContact();
      }
      user.email = email;
    }
    if (request.phone != null) {
      final phone = LocalAuthRules.normalizePhone(request.phone);
      if (phone == null || _phoneTaken(phone, user.id)) {
        throw LocalAuthRules.duplicateContact();
      }
      user.phone = phone;
    }
    return user.toPublicUser();
  }

  ApiException? _loginBlock(UserStatus status) => switch (status) {
    UserStatus.unverified => ApiException(
      'Debes verificar tu cuenta con el código que te enviamos.',
      statusCode: 403,
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
    if (token == null ||
        !token.startsWith(LocalAuthRules.tokenPrefix)) {
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

  AuthSession _sessionFor(LocalUser user) => AuthSession(
    accessToken: '${LocalAuthRules.tokenPrefix}${user.id}',
    user: user.toPublicUser(),
  );
}