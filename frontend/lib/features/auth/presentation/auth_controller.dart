import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/api_exception.dart';
import '../../../core/auth/token_store.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// La cuenta con sesión abierta (`null` sin sesión). Los repositorios de
/// cada feature la miran: al cambiar de cuenta se reconstruyen y, con ellos,
/// todo lo que se había cargado. Sin esto, quien entraba después en el
/// mismo teléfono veía un rato los datos de la cuenta anterior.
final sessionUserIdProvider = Provider<String?>(
  (ref) => ref.watch(
    authControllerProvider.select((state) => state.value?.user?.id),
  ),
);

enum AuthStatus { unauthenticated, authenticated }

class AuthState {
  const AuthState._({required this.status, this.user});

  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  const AuthState.authenticated(PublicUser user)
    : this._(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final PublicUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthController extends AsyncNotifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  TokenStore get _tokenStore => ref.read(tokenStoreProvider);

  @override
  Future<AuthState> build() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      return const AuthState.unauthenticated();
    }

    try {
      final user = await _repository.me();
      return AuthState.authenticated(user);
    } on ApiException catch (error, stackTrace) {
      if (error.statusCode == 401) {
        await _tokenStore.delete();
        return const AuthState.unauthenticated();
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<RegisterResponse> register(RegisterRequest request) {
    return _repository.register(request);
  }

  /// Verifica el código y guarda la sesión. Con [announce] en `false` no
  /// avisa todavía al router (ver [announce]).
  Future<AuthSession> verifyOtp(
    VerifyOtpRequest request, {
    bool announce = true,
  }) async {
    final session = await _repository.verifyOtp(request);
    await _saveSession(session, announce: announce);
    return session;
  }

  Future<AuthMessage> resendOtp(ResendOtpRequest request) {
    return _repository.resendOtp(request);
  }

  /// Inicia sesión y guarda el token. Con [announce] en `false` no avisa
  /// todavía al router (ver [announce]).
  Future<AuthSession> login(LoginRequest request, {bool announce = true}) async {
    final session = await _repository.login(request);
    await _saveSession(session, announce: announce);
    return session;
  }

  /// Publica la sesión ya guardada. El router escucha este estado y, apenas
  /// cambia, saca al usuario de las pantallas públicas hacia `/home`. Por
  /// eso el login y el código lo llaman al terminar su animación de salida:
  /// si se publicara antes, la pantalla se cerraría a mitad del círculo.
  void announce(AuthSession session) {
    state = AsyncData(AuthState.authenticated(session.user));
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      await _tokenStore.delete();
      state = const AsyncData(AuthState.unauthenticated());
    }
  }

  Future<AuthMessage> forgotPassword(ForgotPasswordRequest request) {
    return _repository.forgotPassword(request);
  }

  Future<AuthMessage> resetPassword(ResetPasswordRequest request) {
    return _repository.resetPassword(request);
  }

  Future<PublicUser> updateProfile(UpdateProfileRequest request) async {
    final user = await _repository.updateProfile(request);
    state = AsyncData(AuthState.authenticated(user));
    return user;
  }

  void clearSession() {
    state = const AsyncData(AuthState.unauthenticated());
  }

  Future<void> _saveSession(AuthSession session, {required bool announce}) async {
    await _tokenStore.write(session.accessToken);
    if (announce) this.announce(session);
  }
}
