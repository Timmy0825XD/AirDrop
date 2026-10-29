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

  /// `PATCH /auth/me`. Con un correo distinto exige `currentPassword`; el
  /// correo no cambia todavía: queda en `pendingEmail` y llega un código.
  Future<PublicUser> updateProfile(UpdateProfileRequest request);

  /// `POST /auth/me/email/confirm` — el correo nuevo queda activo.
  Future<PublicUser> confirmEmailChange(String code);

  /// `POST /auth/me/email/resend` — otro código al correo nuevo.
  Future<AuthMessage> resendEmailChange();

  /// `DELETE /auth/me/email/pending` — el correo actual sigue.
  Future<PublicUser> cancelEmailChange();
}
