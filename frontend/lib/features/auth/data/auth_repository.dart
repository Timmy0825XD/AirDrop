import 'auth_models.dart';

abstract class AuthRepository {
  Future<RegisterResponse> register(RegisterRequest request);

  Future<AuthSession> verifyOtp(VerifyOtpRequest request);

  Future<AuthMessage> resendOtp(ResendOtpRequest request);

  Future<AuthSession> login(LoginRequest request);

  Future<void> logout();

  Future<AuthMessage> forgotPassword(ForgotPasswordRequest request);

  Future<AuthMessage> resetPassword(ResetPasswordRequest request);

  Future<PublicUser> me();

  Future<PublicUser> updateProfile(UpdateProfileRequest request);
}
