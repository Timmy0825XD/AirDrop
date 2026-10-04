import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
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
    final unique = DateTime.now().microsecondsSinceEpoch;
    final email = 'nuevo.$unique@correo.co';
    final response = await repository.register(
      RegisterRequest(
        fullName: 'Nueva Cuenta',
        documentType: DocumentType.citizenshipId,
        documentNumber: '$unique'.substring(0, 9),
        phone: '3011234567',
        password: 'secreto12',
        email: email,
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
    expect(session.user.role, UserRole.requester);
    expect(session.user.documentType, DocumentType.citizenshipId);
  });

  test('rechaza un documento que no corresponde al tipo', () async {
    expect(
      () => repository.register(
        RegisterRequest(
          fullName: 'Documento Mal Digitado',
          documentType: DocumentType.citizenshipId,
          documentNumber: 'AB12',
          phone: '3031234567',
          email: 'mal.digitado@correo.co',
          password: 'secreto12',
          consentAccepted: true,
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'mensaje',
          'El número de documento no corresponde a una cédula o a un PPT.',
        ),
      ),
    );
  });

  test('el registro local rechaza una cuenta sin correo', () async {
    final unique = DateTime.now().microsecondsSinceEpoch;
    expect(
      () => repository.register(
        RegisterRequest(
          fullName: 'Nueva Cuenta',
          documentType: DocumentType.citizenshipId,
          documentNumber: '$unique'.substring(0, 8),
          phone: '3010001122',
          email: '   ',
          password: 'secreto12',
          consentAccepted: true,
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'mensaje',
          'El correo es obligatorio.',
        ),
      ),
    );
  });

  test('el registro local siempre nace como solicitante', () async {
    final unique = DateTime.now().microsecondsSinceEpoch;
    await repository.register(
      RegisterRequest(
        fullName: 'Cuenta Con Correo',
        documentType: DocumentType.citizenshipId,
        documentNumber: '$unique'.substring(0, 7),
        phone: '30${unique.toString().substring(6)}',
        password: 'secreto12',
        email: 'con.correo.$unique@correo.co',
        consentAccepted: true,
      ),
    );
    final session = await repository.verifyOtp(
      VerifyOtpRequest(
        contact: AuthContact.email('con.correo.$unique@correo.co'),
        code: '123456',
      ),
    );

    expect(session.user.role, UserRole.requester);
  });

  test('rechaza el documento repetido', () async {
    expect(
      () => repository.register(
        RegisterRequest(
          fullName: 'Documento Repetido',
          documentType: DocumentType.citizenshipId,
          documentNumber: '1098765432',
          phone: '3041234567',
          email: 'repetido@correo.co',
          password: 'secreto12',
          consentAccepted: true,
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'mensaje',
          'Ya existe una cuenta con este documento.',
        ),
      ),
    );
  });

  test('el perfil solo deja editar el documento al solicitante', () async {
    await repository
        .login(
          LoginRequest(
            contact: AuthContact.email('despacho@airdrop.local'),
            password: 'Despacho123',
          ),
        )
        .then((session) => tokenStore.value = session.accessToken);

    expect(
      () => repository.updateProfile(
        const UpdateProfileRequest(
          documentType: DocumentType.citizenshipId,
          documentNumber: '1098765432',
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'mensaje',
          'El documento solo aplica al solicitante.',
        ),
      ),
    );
  });

  test('el solicitante cambia su documento y el perfil lo refleja', () async {
    final session = await repository.login(
      LoginRequest(
        contact: AuthContact.email('demo@airdrop.local'),
        password: 'Demo1234',
      ),
    );
    tokenStore.value = session.accessToken;

    final updated = await repository.updateProfile(
      const UpdateProfileRequest(
        documentType: DocumentType.foreignerId,
        documentNumber: '99887766',
      ),
    );

    expect(updated.documentType, DocumentType.foreignerId);
    expect(updated.documentNumber, '99887766');
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
