import '../auth_models.dart';
import 'local_user.dart';

/// Cuentas de prueba para trabajar sin NestJS. No son credenciales de
/// producción; el OTP local es `123456`.
final List<LocalUser> localFixtureUsers = [
  LocalUser(
    id: '11111111-1111-4111-8111-111111111111',
    fullName: 'Ana Solicitud',
    email: 'demo@airdrop.local',
    phone: '3001234567',
    role: UserRole.requester,
    status: UserStatus.active,
    password: 'Demo1234',
  ),
  LocalUser(
    id: '22222222-2222-4222-8222-222222222222',
    fullName: 'Diego Despacho',
    email: 'despacho@airdrop.local',
    phone: null,
    role: UserRole.dispatcher,
    status: UserStatus.active,
    password: 'Despacho123',
    hubId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  ),
  LocalUser(
    id: '33333333-3333-4333-8333-333333333333',
    fullName: 'Sara Operadora',
    email: 'operador@airdrop.local',
    phone: null,
    role: UserRole.fleetOperator,
    status: UserStatus.active,
    password: 'Operador123',
    hubId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  ),
  LocalUser(
    id: '44444444-4444-4444-8444-444444444444',
    fullName: 'Admin AirDrop',
    email: 'admin@airdrop.local',
    phone: null,
    role: UserRole.admin,
    status: UserStatus.active,
    password: 'Admin1234',
  ),
];

/// Id de la central de demostración que comparten las fixtures
/// institucionales.
const String localFixtureHubId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';