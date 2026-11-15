import '../privacy_models.dart';
import 'local_user.dart';

/// La política de `DataSource.local`: un resumen para trabajar sin Nest.
/// La que vale es la de `GET /privacy/policy`.
const localPrivacyPolicy = PrivacyPolicy(
  version: localPolicyVersion,
  effectiveFrom: '2026-11-14',
  controllerName: 'AirDrop (proyecto académico)',
  contactEmail: 'datos@airdrop.local',
  sections: [
    PolicySection(
      title: 'Qué datos recogemos y para qué',
      body: [
        'Tu nombre, documento, correo y celular, para identificarte y '
            'avisarte de tus pedidos.',
        'Lo que cuentas al pedir y tu fórmula médica, para que un '
            'despachador decida si se puede enviar.',
      ],
    ),
    PolicySection(
      title: 'Tus derechos (Ley 1581, art. 8)',
      body: [
        'Conocer, actualizar y rectificar tus datos.',
        'Revocar el consentimiento y pedir la supresión de tu cuenta.',
      ],
    ),
  ],
);

const localRevokeNotice = [
  'Tu cuenta queda inactiva y no podrás iniciar sesión.',
  'Se cancelan los pedidos que todavía no tienen dron.',
  'Dejas de recibir correos de AirDrop.',
];

const localSuppressNotice = [
  'Se borran tu correo, tu celular, tu documento y tu contraseña.',
  'Los pedidos ya entregados quedan sin tu nombre.',
  'No se puede deshacer.',
];
