import { ContingencyProtocol } from '../common/enums/contingency-protocol.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import type { FlightProgress } from './simulation.rules';

/** RF-48: el operador que firma cada vuelo. */
export const REMOTE_ID_OPERATOR = 'AirDrop';

/** RF-48: el estado que emite la identificación (`operacion/manifiesto.md`). */
export enum RemoteIdStatus {
  MISSION = 'mission',
  RETURNING = 'returning',
  LINK_LOST = 'link_lost',
  EMERGENCY = 'emergency',
}

/**
 * RF-48: identificación al estilo Remote ID que viaja con cada tick:
 * matrícula, operador, tipo, manifiesto vigente y estado.
 */
export type RemoteId = {
  registration: string;
  operator: string;
  type: string;
  manifestNumber: string | null;
  status: RemoteIdStatus;
};

const EMERGENCY_PROTOCOLS = new Set<ContingencyProtocol>([
  ContingencyProtocol.EMERGENCY_LANDING,
  ContingencyProtocol.CRASH,
]);

export function remoteIdStatus(
  progress: Pick<FlightProgress, 'linkLost' | 'contingency'>,
  leg: RouteLeg,
): RemoteIdStatus {
  if (progress.linkLost) {
    return RemoteIdStatus.LINK_LOST;
  }
  if (
    progress.contingency &&
    EMERGENCY_PROTOCOLS.has(progress.contingency.protocol)
  ) {
    return RemoteIdStatus.EMERGENCY;
  }
  return leg === RouteLeg.RETURN
    ? RemoteIdStatus.RETURNING
    : RemoteIdStatus.MISSION;
}

export function buildRemoteId(input: {
  identifier: string;
  typeName: string;
  manifestNumber: string | null;
  progress: Pick<FlightProgress, 'linkLost' | 'contingency'>;
  leg: RouteLeg;
}): RemoteId {
  return {
    registration: input.identifier,
    operator: REMOTE_ID_OPERATOR,
    type: input.typeName,
    manifestNumber: input.manifestNumber,
    status: remoteIdStatus(input.progress, input.leg),
  };
}
