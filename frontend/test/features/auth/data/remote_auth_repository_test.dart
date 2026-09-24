import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/token_store.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/data/remote/remote_auth_repository.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(tokenStore: FakeTokenStore());

  final calls = <String>[];

  @override
  Future<dynamic> getJson(String path) async {
    calls.add('GET $path');
    return _user;
  }

  @override
  Future<dynamic> postJson(String path, {Object? body}) async {
    calls.add('POST $path');
    return _responseFor(path);
  }

  @override
  Future<dynamic> patchJson(String path, {Object? body}) async {
    calls.add('PATCH $path');
    return _user;
  }

  @override
  Future<void> postEmpty(String path) async {
    calls.add('EMPTY $path');
  }

  Map<String, dynamic> get _user => {
    'id': 'user-1',
    'fullName': 'Ana Pérez',
    'email': 'ana@correo.co',
    'phone': null,
    'role': 'requester',
    'status': 'active',
    'hubId': null,
  };

  Map<String, dynamic> _responseFor(String path) {
    if (path == '/auth/register') {
      return {'message': 'Cuenta creada.', 'userId': 'user-1'};
    }
    if (path == '/auth/verify-otp' || path == '/auth/login') {
      return {'accessToken': 'token', 'user': _user};
    }
    return {'message': 'Operación completada.'};
  }
}

class FakeTokenStore extends TokenStore {
  FakeTokenStore() : super();

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> delete() async {}
}

void main() {
  test('usa los nueve endpoints del contrato de Auth', () async {
    final client = FakeApiClient();
    final repository = RemoteAuthRepository(apiClient: client);
    final contact = AuthContact.email('ana@correo.co');

    await repository.register(
      RegisterRequest(
        fullName: 'Ana Pérez',
        email: 'ana@correo.co',
        password: 'secreto12',
        role: UserRole.requester,
        consentAccepted: true,
      ),
    );
    await repository.verifyOtp(
      VerifyOtpRequest(contact: contact, code: '123456'),
    );
    await repository.resendOtp(ResendOtpRequest(contact: contact));
    await repository.login(
      LoginRequest(contact: contact, password: 'secreto12'),
    );
    await repository.logout();
    await repository.forgotPassword(ForgotPasswordRequest(contact: contact));
    await repository.resetPassword(
      ResetPasswordRequest(
        contact: contact,
        code: '123456',
        password: 'secreto34',
      ),
    );
    await repository.me();
    await repository.updateProfile(
      UpdateProfileRequest(fullName: 'Ana Actualizada'),
    );

    expect(client.calls, [
      'POST /auth/register',
      'POST /auth/verify-otp',
      'POST /auth/resend-otp',
      'POST /auth/login',
      'EMPTY /auth/logout',
      'POST /auth/forgot-password',
      'POST /auth/reset-password',
      'GET /auth/me',
      'PATCH /auth/me',
    ]);
  });
}
