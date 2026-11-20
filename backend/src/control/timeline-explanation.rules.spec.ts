import { DestinationKind } from '../common/enums/destination-kind.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { DecisionTrace, HubTrace } from '../orders/order.entity';
import {
  explainAssignment,
  explainNoFlight,
} from './timeline-explanation.rules';

const urgency = {
  missionType: MissionType.EMERGENCY,
  destinationKind: DestinationKind.PERSON,
  medicationName: 'Insulina glargina 100 UI',
};

function hub(overrides: Partial<HubTrace>): HubTrace {
  return {
    hubId: 'hub',
    name: 'Central',
    lot: true,
    corridorKm: 11,
    etaMin: 6,
    batteryNeededPercent: 40,
    inRange: true,
    note: null,
    drones: [],
    ...overrides,
  };
}

const north = hub({
  hubId: 'north',
  name: 'Central Norte (Río Seco)',
  corridorKm: 11.2,
  etaMin: 6.1,
  drones: [
    {
      identifier: 'AD-NOR-01',
      typeName: 'Colibrí',
      status: 'chosen',
      reason: null,
      preempts: false,
      batteryPercent: 92,
    },
    {
      identifier: 'AD-NOR-03',
      typeName: 'Garza',
      status: 'discarded',
      reason: 'No tiene batería para ida, regreso y reserva.',
      preempts: false,
      batteryPercent: 41,
    },
    {
      identifier: 'AD-NOR-02',
      typeName: 'Colibrí',
      status: 'discarded',
      reason: 'El pedido exige frío y el dron no tiene compartimento.',
      preempts: false,
      batteryPercent: 100,
    },
  ],
});

const valledupar = hub({
  hubId: 'vup',
  name: 'Central Valledupar',
  corridorKm: 25,
  etaMin: 14.2,
  drones: [
    {
      identifier: 'AD-VUP-01',
      typeName: 'Colibrí',
      status: 'eligible',
      reason: null,
      preempts: false,
      batteryPercent: 100,
    },
  ],
});

const trace: DecisionTrace = {
  at: '2026-11-16T15:44:00.000Z',
  outcome: 'assigned',
  reason: null,
  hubs: [
    north,
    valledupar,
    hub({ hubId: 'west', name: 'Central Occidente', lot: false }),
  ],
};

describe('Explicación de la decisión para la TV (RF-39, RF-11)', () => {
  it('dice por qué esta central, con la llegada y la otra central que podía', () => {
    const [nodeSection] = explainAssignment(trace, urgency)!;
    expect(nodeSection.title).toBe('Por qué esta central');
    expect(nodeSection.lines).toEqual([
      'Central Norte (Río Seco) tiene el medicamento con lote vigente y está a 11,2 km: llega en 6 min.',
      'Central Valledupar también podía, pero tardaría 14 min.',
      'Central Occidente no tiene el medicamento con lote vigente.',
    ]);
  });

  it('dice por qué este dron y por qué no los otros', () => {
    const [, droneSection] = explainAssignment(trace, urgency)!;
    expect(droneSection.title).toBe('Por qué este dron');
    expect(droneSection.lines).toEqual([
      'Es una urgencia: gana el que llega antes, y ese es el Colibrí AD-NOR-01. Sale con 92 % de batería.',
      'El Garza AD-NOR-03 no: no tiene batería para ida, regreso y reserva.',
      'El Colibrí AD-NOR-02 no: el pedido exige frío y el dron no tiene compartimento.',
    ]);
  });

  it('no nombra el medicamento de una persona; el de una central sí', () => {
    const forPerson = JSON.stringify(explainAssignment(trace, urgency));
    expect(forPerson).not.toContain('Insulina');
    const forHub = JSON.stringify(
      explainAssignment(trace, {
        ...urgency,
        destinationKind: DestinationKind.HUB,
      }),
    );
    expect(forHub).toContain('Insulina glargina 100 UI con lote vigente');
  });

  it('en un programado gana el que gasta menos', () => {
    const [, droneSection] = explainAssignment(trace, {
      ...urgency,
      missionType: MissionType.SCHEDULED,
    })!;
    expect(droneSection.lines[0]).toContain('gana el que gasta menos batería');
  });

  it('cuando no sale ningún dron, explica por qué en cada central', () => {
    const blocked: DecisionTrace = {
      ...trace,
      outcome: 'conventional',
      reason: 'Ningún dron puede llegar',
      hubs: [
        hub({ name: 'Central Norte', inRange: false }),
        hub({ name: 'Central Codazzi', corridorKm: null }),
      ],
    };
    expect(explainNoFlight(blocked, urgency)).toEqual([
      {
        title: 'Por qué no salió un dron',
        lines: [
          'Ningún dron puede llegar.',
          'Central Norte queda lejos: sus drones no alcanzan a ir y volver.',
          'Central Codazzi no tiene una ruta libre de zonas restringidas.',
        ],
      },
    ]);
  });

  it('sin traza no inventa nada', () => {
    expect(explainAssignment(null, urgency)).toBeNull();
  });
});
