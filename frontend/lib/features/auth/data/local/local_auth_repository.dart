import '../../../../core/api_exception.dart';
import '../../../../core/auth/token_store.dart';
import '../auth_models.dart';
import '../auth_repository.dart';

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({TokenStore? tokenStore})
    : _tokenStore = tokenStore ?? TokenStore(),
      _users = {for (final user in _fixtureUsers) user.id: user.copy()};

  static const _otp = '123456';
  static const _tokenPrefix = 'local-session:';
  static const _resetMessage =
      'Si el contacto existe, te enviaremos un código.';

  final TokenStore _tokenStore;
  final Map<String, _LocalUser> _users;

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    if (!request.role.canSelfRegister) {
      throw ApiException(
        'El rol no es válido para el registro.',
        statusCode: 400,
      );
    }

    final email = _normalizeEmail(request.email);
    final phone = _normalizePhone(request.phone);
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
    if (duplicate) {
      throw ApiException(
        'Ya existe una cuenta con este correo o celular.',
        statusCode: 409,
      );
    }

    final id = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final user = _LocalUser(
      id: id,
      fullName: request.fullName.trim(),
      email: email,
      phone: phone,
      role: request.role,
      status: UserStatus.unverified,
      password: request.password,
    );
    _users[id] = user;
    return RegisterResponse(
      message: 'Cuenta creada. Verifica el código para activarla.',
      userId: id,
    );
  }

  @override
  Future<AuthSession> verifyOtp(VerifyOtpRequest request) async {
    final user = _requireUser(request.contact);
    if (user.status != UserStatus.unverified || request.code != _otp) {
      throw _invalidOtp();
    }
    user.status = UserStatus.active;
    return _sessionFor(user);
  }

  @override
  Future<AuthMessage> resendOtp(ResendOtpRequest request) async {
    _requireUser(request.contact);
    return const AuthMessage(
      message: 'Si el contacto existe, te enviaremos un código.',
    );
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
    if (user.status == UserStatus.unverified) {
      throw ApiException(
        'Debes verificar tu cuenta con el código que te enviamos.',
        statusCode: 403,
      );
    }
    if (user.status == UserStatus.locked) {
      throw ApiException(
        'Demasiados intentos. Intenta de nuevo en unos minutos.',
        statusCode: 403,
      );
    }
    if (user.status == UserStatus.suspended) {
      throw ApiException(
        'Tu cuenta está suspendida. Habla con el administrador.',
        statusCode: 403,
      );
    }
    return _sessionFor(user);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthMessage> forgotPassword(ForgotPasswordRequest request) async {
    return const AuthMessage(message: _resetMessage);
  }

  @override
  Future<AuthMessage> resetPassword(ResetPasswordRequest request) async {
    final user = _findByContact(request.contact);
    if (user == null || request.code != _otp) {
      throw ApiException(_resetMessage, statusCode: 400);
    }
    user.password = request.password;
    return const AuthMessage(
      message: 'La contraseña se actualizó. Ya puedes iniciar sesión.',
    );
  }

  @override
  Future<PublicUser> me() async {
    final token = await _tokenStore.read();
    final user = _userForToken(token);
    if (user == null) {
      throw ApiException(
        'Tu sesión expiró. Inicia sesión de nuevo.',
        statusCode: 401,
      );
    }
    return _toPublicUser(user);
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
      final email = _normalizeEmail(request.email);
      if (email == null || _emailTaken(email, user.id)) {
        throw ApiException(
          'Ya existe una cuenta con este correo o celular.',
          statusCode: 409,
        );
      }
      user.email = email;
    }
    if (request.phone != null) {
      final phone = _normalizePhone(request.phone);
      if (phone == null || _phoneTaken(phone, user.id)) {
        throw ApiException(
          'Ya existe una cuenta con este correo o celular.',
          statusCode: 409,
        );
      }
      user.phone = phone;
    }
    return _toPublicUser(user);
  }

  _LocalUser _requireUser(AuthContact contact) {
    final user = _findByContact(contact);
    if (user == null) {
      throw _invalidOtp();
    }
    return user;
  }

  Future<_LocalUser> _requireSessionUser() async {
    final user = _userForToken(await _tokenStore.read());
    if (user == null) {
      throw ApiException(
        'Tu sesión expiró. Inicia sesión de nuevo.',
        statusCode: 401,
      );
    }
    return user;
  }

  _LocalUser? _findByContact(AuthContact contact) {
    final email = _normalizeEmail(contact.email);
    final phone = _normalizePhone(contact.phone);
    for (final user in _users.values) {
      if (email != null && user.email == email) {
        return user;
      }
      if (phone != null && user.phone == phone) {
        return user;
      }
    }
    return null;
  }

  _LocalUser? _userForToken(String? token) {
    if (token == null || !token.startsWith(_tokenPrefix)) {
      return null;
    }
    return _users[token.substring(_tokenPrefix.length)];
  }

  bool _emailTaken(String email, String currentId) {
    return _users.values.any(
      (user) => user.id != currentId && user.email == email,
    );
  }

  bool _phoneTaken(String phone, String currentId) {
    return _users.values.any(
      (user) => user.id != currentId && user.phone == phone,
    );
  }

  AuthSession _sessionFor(_LocalUser user) {
    return AuthSession(
      accessToken: '$_tokenPrefix${user.id}',
      user: _toPublicUser(user),
    );
  }

  PublicUser _toPublicUser(_LocalUser user) {
    return PublicUser(
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      status: user.status,
      hubId: user.hubId,
    );
  }

  ApiException _invalidOtp() {
    return ApiException('El código es inválido o ya venció.', statusCode: 400);
  }

  static String? _normalizeEmail(String? value) {
    final email = value?.trim().toLowerCase();
    return email == null || email.isEmpty ? null : email;
  }

  static String? _normalizePhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\D'), '');
    return phone == null || phone.isEmpty ? null : phone;
  }
}

class _LocalUser {
  _LocalUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.password,
    this.hubId,
  });

  final String id;
  String fullName;
  String? email;
  String? phone;
  final UserRole role;
  UserStatus status;
  String password;
  final String? hubId;

  _LocalUser copy() {
    return _LocalUser(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      status: status,
      password: password,
      hubId: hubId,
    );
  }
}

final List<_LocalUser> _fixtureUsers = [
  _LocalUser(
    id: '11111111-1111-4111-8111-111111111111',
    fullName: 'Ana Solicitud',
    email: 'demo@airdrop.local',
    phone: '3001234567',
    role: UserRole.requester,
    status: UserStatus.active,
    password: 'Demo1234',
  ),
  _LocalUser(
    id: '22222222-2222-4222-8222-222222222222',
    fullName: 'Diego Despacho',
    email: 'despacho@airdrop.local',
    phone: null,
    role: UserRole.dispatcher,
    status: UserStatus.active,
    password: 'Despacho123',
    hubId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  ),
  _LocalUser(
    id: '33333333-3333-4333-8333-333333333333',
    fullName: 'Sara Operadora',
    email: 'operador@airdrop.local',
    phone: null,
    role: UserRole.fleetOperator,
    status: UserStatus.active,
    password: 'Operador123',
    hubId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  ),
  _LocalUser(
    id: '44444444-4444-4444-8444-444444444444',
    fullName: 'Admin AirDrop',
    email: 'admin@airdrop.local',
    phone: null,
    role: UserRole.admin,
    status: UserStatus.active,
    password: 'Admin1234',
  ),
];
