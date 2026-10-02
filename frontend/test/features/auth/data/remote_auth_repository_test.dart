import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/token_store.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/data/remote/remote_auth_repository.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(tokenStore: FakeTokenStore());

  final calls = <String>[];

  @override
  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
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
    'phone': '3001234567',
    'documentType': 'citizenship_id',
    'documentNumber': '1098765432',
    'role': 'requester',
    'status': 'active',
    'hubIds': <String>[],
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
        documentType: DocumentType.citizenshipId,
        documentNumber: '1098765432',
        phone: '3001234567',
        password: 'secreto12',
        email: 'ana@correo.co',
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

    // El PATCH del documento manda tipo y número juntos: Nest rechaza
    // que llegue uno sin el otro.
    await repository.updateProfile(
      const UpdateProfileRequest(
        documentType: DocumentType.ppt,
        documentNumber: 'AB123456',
      ),
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
      'PATCH /auth/me',
    ]);
  });

  test('lee documentType y hubIds de la respuesta de Nest', () async {
    final repository = RemoteAuthRepository(apiClient: FakeApiClient());

    final user = await repository.me();

    expect(user.documentType, DocumentType.citizenshipId);
    expect(user.documentNumber, '1098765432');
    expect(user.hubIds, isEmpty);
  });
}
