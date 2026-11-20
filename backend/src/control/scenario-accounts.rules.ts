import { DocumentType } from '../common/enums/document-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { hubPlans, operator, requesters } from './demo-scenario';

/**
 * RF-40: una cuenta del escenario tal como la deja `pnpm seed:demo`, con las
 * centrales (por nombre) a las que queda asignada.
 */
export type ScenarioAccount = {
  fullName: string;
  email: string;
  phone: string;
  role: UserRole;
  documentType: DocumentType | null;
  documentNumber: string | null;
  hubNames: string[];
};

/**
 * Las cuentas del escenario: los despachadores de cada central (solo la
 * suya), el operador (todas) y los solicitantes (ninguna).
 */
export function scenarioAccounts(): ScenarioAccount[] {
  const dispatchers = hubPlans.flatMap((plan) =>
    plan.dispatchers.map((person) => ({
      ...person,
      role: UserRole.DISPATCHER,
      documentType: null,
      documentNumber: null,
      hubNames: [plan.name],
    })),
  );
  return [
    ...dispatchers,
    {
      ...operator,
      role: UserRole.FLEET_OPERATOR,
      documentType: null,
      documentNumber: null,
      hubNames: hubPlans.map((plan) => plan.name),
    },
    ...requesters.map((person) => ({
      ...person,
      role: UserRole.REQUESTER,
      hubNames: [],
    })),
  ];
}

/**
 * Las cuentas que el reinicio borra: todas menos las del escenario y los
 * administradores. Los solicitantes simulados también se van; el generador
 * de pedidos los vuelve a crear cuando hacen falta (RF-37).
 */
export function isScenarioAccount(
  user: { email: string | null; role: UserRole },
  emails: ReadonlySet<string>,
): boolean {
  return (
    user.role === UserRole.ADMIN ||
    (user.email !== null && emails.has(user.email))
  );
}
