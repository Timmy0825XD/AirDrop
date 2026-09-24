import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/token_store.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/data/local/local_auth_repository.dart';

class FakeTokenStore extends TokenStore {
  FakeTokenStore() : super();

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> delete() async => value = null;
}

void main() {
  late FakeTokenStore tokenStore;
  late LocalAuthRepository repository;

  setUp(() {
    tokenStore = FakeTokenStore();
    repository = LocalAuthRepository(tokenStore: tokenStore);
  });

  test('inicia sesión y recupera el usuario con me', () async {
    final session = await repository.login(
      LoginRequest(
        contact: AuthContact.email('demo@airdrop.local'),
        password: 'Demo1234',
      ),
    );
    tokenStore.value = session.accessToken;

    final user = await repository.me();

    expect(user.email, 'demo@airdrop.local');
    expect(user.role, UserRole.requester);
  });

  test('registra y verifica una cuenta local', () async {
    final email = 'nuevo.${DateTime.now().microsecondsSinceEpoch}@correo.co';
    final response = await repository.register(
      RegisterRequest(
        fullName: 'Nueva Cuenta',
        email: email,
        phone: '3011234567',
        password: 'secreto12',
        role: UserRole.requester,
        consentAccepted: true,
      ),
    );

    expect(response.userId, startsWith('local-'));
    final session = await repository.verifyOtp(
      VerifyOtpRequest(contact: AuthContact.email(email), code: '123456'),
    );

    expect(session.user.status, UserStatus.active);
    expect(session.user.email, email);
    expect(session.user.phone, '3011234567');
  });

  test('restablece la contraseña y permite iniciar sesión', () async {
    await repository.resetPassword(
      ResetPasswordRequest(
        contact: AuthContact.email('demo@airdrop.local'),
        code: '123456',
        password: 'NuevaClave9',
      ),
    );

    final session = await repository.login(
      LoginRequest(
        contact: AuthContact.email('demo@airdrop.local'),
        password: 'NuevaClave9',
      ),
    );

    expect(session.user.email, 'demo@airdrop.local');
  });
}
