import { ContingencyProtocol } from '../common/enums/contingency-protocol.enum';
import { RouteLeg } from '../common/enums/route-leg.enum';
import {
  RemoteIdStatus,
  buildRemoteId,
  remoteIdStatus,
} from './remote-id.rules';

describe('Identificación remota (RF-48)', () => {
  it('lleva matrícula, operador, tipo y manifiesto vigente', () => {
    expect(
      buildRemoteId({
        identifier: 'AD-NOR-03',
        typeName: 'Garza',
        manifestNumber: 'MAN-2026-000123',
        progress: {},
        leg: RouteLeg.OUTBOUND,
      }),
    ).toEqual({
      registration: 'AD-NOR-03',
      operator: 'AirDrop',
      type: 'Garza',
      manifestNumber: 'MAN-2026-000123',
      status: RemoteIdStatus.MISSION,
    });
  });

  it('el estado: sin enlace gana, luego emergencia, luego regreso', () => {
    const landing = {
      contingency: {
        protocol: ContingencyProtocol.EMERGENCY_LANDING,
        incidentId: 'i',
      },
    };
    expect(
      remoteIdStatus({ linkLost: true, ...landing }, RouteLeg.RETURN),
    ).toBe(RemoteIdStatus.LINK_LOST);
    expect(remoteIdStatus(landing, RouteLeg.OUTBOUND)).toBe(
      RemoteIdStatus.EMERGENCY,
    );
    expect(remoteIdStatus({}, RouteLeg.RETURN)).toBe(RemoteIdStatus.RETURNING);
  });
});
