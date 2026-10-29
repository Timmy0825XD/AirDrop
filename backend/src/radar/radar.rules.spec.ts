import { DestinationKind } from '../common/enums/destination-kind.enum';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { MissionType } from '../common/enums/mission-type.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { canWatchRadar } from '../telemetry/telemetry.rules';
import { countFleet, presentRadarFlight } from './radar.rules';

const drone = { id: 'd1', identifier: 'WG-198-001', hubId: 'h1' };

function order(destinationKind: DestinationKind) {
  return {
    id: 'o1',
    missionType: MissionType.EMERGENCY,
    destinationKind,
    destinationHubId: destinationKind === DestinationKind.HUB ? 'h2' : null,
    status: OrderStatus.IN_FLIGHT,
    quantity: 2,
    requiresColdChain: true,
    medicationName: 'Insulina',
    coldChainAlertAt: null,
  };
}

describe('countFleet', () => {
  it('cuenta cada estado y el total', () => {
    const counts = countFleet([
      { status: DroneStatus.AVAILABLE },
      { status: DroneStatus.AVAILABLE },
      { status: DroneStatus.IN_MISSION },
      { status: DroneStatus.MAINTENANCE },
      { status: DroneStatus.OUT_OF_SERVICE },
    ]);
    expect(counts).toEqual({
      available: 2,
      inMission: 1,
      maintenance: 1,
      outOfService: 1,
      total: 5,
    });
  });
});

describe('presentRadarFlight', () => {
  const alerts = { battery: false, failure: false };

  it('no revela el medicamento cuando el destino es una persona', () => {
    const view = presentRadarFlight(
      drone,
      order(DestinationKind.PERSON),
      null,
      alerts,
    );
    expect(view.medicationName).toBeNull();
    expect(JSON.stringify(view)).not.toContain('Insulina');
  });

  it('dice el medicamento en un traslado entre centrales', () => {
    const view = presentRadarFlight(
      drone,
      order(DestinationKind.HUB),
      null,
      alerts,
    );
    expect(view.medicationName).toBe('Insulina');
  });

  it('sin telemetría deja la posición en null', () => {
    const view = presentRadarFlight(
      drone,
      order(DestinationKind.HUB),
      null,
      alerts,
    );
    expect(view.latitude).toBeNull();
    expect(view.phase).toBeNull();
  });

  it('marca la alerta de frío cuando el pedido la trae', () => {
    const view = presentRadarFlight(
      drone,
      { ...order(DestinationKind.HUB), coldChainAlertAt: new Date() },
      null,
      alerts,
    );
    expect(view.alerts.coldChain).toBe(true);
  });
});

describe('canWatchRadar', () => {
  it('solo el administrador', () => {
    expect(canWatchRadar(UserRole.ADMIN)).toBe(true);
    expect(canWatchRadar(UserRole.DISPATCHER)).toBe(false);
    expect(canWatchRadar(UserRole.FLEET_OPERATOR)).toBe(false);
    expect(canWatchRadar(UserRole.REQUESTER)).toBe(false);
  });
});
