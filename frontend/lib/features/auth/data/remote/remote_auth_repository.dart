import '../../../../core/network/api_client.dart';
import '../auth_models.dart';
import '../auth_repository.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    final data = await apiClient.postJson(
      '/auth/register',
      body: request.toJson(),
    );
    return RegisterResponse.fromJson(_asJsonMap(data));
  }

  @override
  Future<AuthSession> verifyOtp(VerifyOtpRequest request) async {
    final data = await apiClient.postJson(
      '/auth/verify-otp',
      body: request.toJson(),
    );
    return AuthSession.fromJson(_asJsonMap(data));
  }

  @override
  Future<AuthMessage> resendOtp(ResendOtpRequest request) async {
    final data = await apiClient.postJson(
      '/auth/resend-otp',
      body: request.toJson(),
    );
    return AuthMessage.fromJson(_asJsonMap(data));
  }

  @override
  Future<AuthSession> login(LoginRequest request) async {
    final data = await apiClient.postJson(
      '/auth/login',
      body: request.toJson(),
    );
    return AuthSession.fromJson(_asJsonMap(data));
  }

  @override
  Future<void> logout() => apiClient.postEmpty('/auth/logout');

  @override
  Future<AuthMessage> forgotPassword(ForgotPasswordRequest request) async {
    final data = await apiClient.postJson(
      '/auth/forgot-password',
      body: request.toJson(),
    );
    return AuthMessage.fromJson(_asJsonMap(data));
  }

  @override
  Future<AuthMessage> resetPassword(ResetPasswordRequest request) async {
    final data = await apiClient.postJson(
      '/auth/reset-password',
      body: request.toJson(),
    );
    return AuthMessage.fromJson(_asJsonMap(data));
  }

  @override
  Future<PublicUser> me() async {
    final data = await apiClient.getJson('/auth/me');
    return PublicUser.fromJson(_asJsonMap(data));
  }

  @override
  Future<PublicUser> updateProfile(UpdateProfileRequest request) async {
    final data = await apiClient.patchJson('/auth/me', body: request.toJson());
    return PublicUser.fromJson(_asJsonMap(data));
  }

  Map<String, dynamic> _asJsonMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map<Object?, Object?>) {
      return Map<String, dynamic>.from(data);
    }
    throw const FormatException(
      'La respuesta del servidor no es un objeto JSON.',
    );
  }
}
