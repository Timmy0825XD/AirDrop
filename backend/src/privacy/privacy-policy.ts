/**
 * RF-50 y `context/legal/datos.md`: la política de tratamiento, versionada.
 * Un cambio sustancial sube `SUBSTANTIAL_POLICY_VERSION` y obliga a aceptarla
 * otra vez en el siguiente ingreso; un cambio de redacción solo sube
 * `POLICY_VERSION`.
 */
export const POLICY_VERSION = '1.0';
export const SUBSTANTIAL_POLICY_VERSION = '1.0';
export const POLICY_EFFECTIVE_FROM = '2026-11-14';

export const DEFAULT_CONTROLLER_NAME = 'AirDrop — proyecto académico';
export const DEFAULT_CONTACT_EMAIL = 'privacidad@airdrop.example';

export type PolicyView = {
  version: string;
  substantialVersion: string;
  effectiveFrom: string;
  controller: { name: string; contactEmail: string };
  sections: Array<{ title: string; body: string[] }>;
};

/** El contenido mínimo del Decreto 1377, art. 13, en el orden de `datos.md`. */
export function privacyPolicy(controller: {
  name: string;
  contactEmail: string;
}): PolicyView {
  return {
    version: POLICY_VERSION,
    substantialVersion: SUBSTANTIAL_POLICY_VERSION,
    effectiveFrom: POLICY_EFFECTIVE_FROM,
    controller,
    sections: [
      {
        title: 'Responsable del tratamiento',
        body: [`${controller.name}. Contacto: ${controller.contactEmail}.`],
      },
      {
        title: 'Qué datos recogemos y para qué',
        body: [
          'Cuenta: nombre, documento, celular y correo, para identificarte y avisarte.',
          'Fórmula: para que la central verifique que puede dispensar el medicamento.',
          'Entrega: el punto de entrega y el código, para que recibas el pedido.',
          'Seguridad del vuelo: el manifiesto describe la carga, no a la persona.',
          'Estadística: el dashboard usa agregados y no identifica a nadie.',
        ],
      },
      {
        title: 'Datos sensibles',
        body: [
          'El tamizaje, las alergias y la fórmula son datos de salud.',
          'Responder el tamizaje y las alergias es opcional: puedes pedir sin responder.',
        ],
      },
      {
        title: 'Tus derechos (Ley 1581, art. 8)',
        body: [
          'Conocer, actualizar y rectificar tus datos.',
          'Pedir prueba de la autorización y saber cómo se usan.',
          'Revocar la autorización y pedir la supresión.',
          'Quejarte ante la Superintendencia de Industria y Comercio.',
        ],
      },
      {
        title: 'Cómo ejercerlos',
        body: [
          `Desde "Mis datos" en tu perfil o escribiendo a ${controller.contactEmail}.`,
          'Una consulta se responde en 10 días hábiles y un reclamo en 15 (arts. 14 y 15).',
        ],
      },
      {
        title: 'Encargados y dónde están los datos',
        body: [
          'Base de datos y archivos en Supabase (São Paulo, Brasil); servidor en Render (EE. UU.); caché en Upstash; correo en Brevo.',
          'Los datos se transmiten a esos encargados bajo un contrato de transmisión (Decreto 1377, art. 25); no se transfieren a otro responsable.',
        ],
      },
      {
        title: 'Cuánto se conservan',
        body: [
          'Al pedir la supresión se borran tu correo, tu celular y tu contraseña, y tus pedidos se anonimizan.',
          'El medicamento, el lote, la fecha y el punto se conservan: la norma farmacéutica obliga a guardar el registro de dispensación.',
          'La imagen de la fórmula se borra cuando vence su plazo de conservación; hasta entonces solo la ve la central que la recibió.',
        ],
      },
      {
        title: 'Vigencia',
        body: [
          `Versión ${POLICY_VERSION}, vigente desde ${POLICY_EFFECTIVE_FROM}.`,
        ],
      },
    ],
  };
}
