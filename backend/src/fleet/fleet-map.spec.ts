import { ForbiddenException } from '@nestjs/common';
import { DroneStatus } from '../common/enums/drone-status.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { HubType } from '../common/enums/hub-type.enum';
import { UserRole } from '../common/enums/user-role.enum';
import { GeofencesService } from '../geofences/geofences.service';
import { User } from '../users/user.entity';
import { FleetFlightsService } from './fleet-flights.service';
import { FleetMapService } from './fleet-map.service';

const HUB_A = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const HUB_B = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const HUB_C = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

/** Una central como sale de la base, con lo que el operador no debe ver. */
const rosario = {
  id: HUB_A,
  name: 'Hospital Rosario Pumarejo',
  type: HubType.HOSPITAL,
  status: HubStatus.ACTIVE,
  latitude: 10.46314,
  longitude: -73.25322,
  address: 'Calle 16 No. 19-35, Valledupar',
  contactPhone: '3001234567',
  contactEmail: 'urgencias.rosario@gmail.com',
  createdByUserId: '99999999-9999-4999-8999-999999999999',
};
const clinica = {
  ...rosario,
  id: HUB_B,
  name: 'Clínica Laura Daniela',
  type: HubType.CLINIC,
  status: HubStatus.SUSPENDED,
  latitude: 10.4742,
  longitude: -73.2598,
};

const drones = [
  { id: 'd1', hubId: HUB_A, status: DroneStatus.AVAILABLE },
  { id: 'd2', hubId: HUB_A, status: DroneStatus.IN_MISSION },
  { id: 'd3', hubId: HUB_A, status: DroneStatus.MAINTENANCE },
  { id: 'd4', hubId: HUB_B, status: DroneStatus.OUT_OF_SERVICE },
];

const geofence = {
  id: '77777777-7777-4777-8777-777777777777',
  name: 'Plaza Alfonso López',
  reason: 'Evento',
  polygon: { type: 'Polygon' as const, coordinates: [] },
  createdByUserId: '88888888-8888-4888-8888-888888888888',
  createdAt: new Date('2026-11-05T15:00:00.000Z'),
};

const flight = { droneId: 'd2', orderId: 'o1', hubId: HUB_A };

function operator(hubIds = [HUB_A, HUB_B]): User {
  return {
    id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    role: UserRole.FLEET_OPERATOR,
    hubAssignments: hubIds.map((hubId) => ({ hubId })),
  } as unknown as User;
}

function build() {
  const hubs = { find: jest.fn().mockResolvedValue([rosario, clinica]) };
  const droneRepo = { find: jest.fn().mockResolvedValue(drones) };
  const geofences = { list: jest.fn().mockResolvedValue([geofence]) };
  const flights = { listFlights: jest.fn().mockResolvedValue([flight]) };
  const service = new FleetMapService(
    hubs as never,
    droneRepo as never,
    geofences as unknown as GeofencesService,
    flights as unknown as FleetFlightsService,
  );
  return { service, hubs, flights };
}

describe('GET /fleet/map', () => {
  it('trae las centrales del operador con su flota, las geovallas y los vuelos', async () => {
    const { service } = build();
    const map = await service.map(operator());
    expect(map.hubs).toEqual([
      {
        id: HUB_A,
        name: 'Hospital Rosario Pumarejo',
        type: HubType.HOSPITAL,
        status: HubStatus.ACTIVE,
        latitude: 10.46314,
        longitude: -73.25322,
        fleet: {
          available: 1,
          inMission: 1,
          maintenance: 1,
          grounded: 0,
          outOfService: 0,
          total: 3,
        },
      },
      {
        id: HUB_B,
        name: 'Clínica Laura Daniela',
        type: HubType.CLINIC,
        status: HubStatus.SUSPENDED,
        latitude: 10.4742,
        longitude: -73.2598,
        fleet: {
          available: 0,
          inMission: 0,
          maintenance: 0,
          grounded: 0,
          outOfService: 1,
          total: 1,
        },
      },
    ]);
    expect(map.geofences).toEqual([
      {
        id: geofence.id,
        name: 'Plaza Alfonso López',
        reason: 'Evento',
        polygon: geofence.polygon,
      },
    ]);
    expect(map.flights).toEqual([flight]);
  });

  it('de una central no manda dirección, contactos ni quién la creó', async () => {
    const { service } = build();
    const json = JSON.stringify(await service.map(operator()));
    for (const leak of [
      'address',
      'Calle 16',
      'contactPhone',
      'contactEmail',
      'createdByUserId',
    ]) {
      expect(json).not.toContain(leak);
    }
  });

  it('solo busca las centrales asignadas', async () => {
    const { service, hubs } = build();
    await service.map(operator());
    const [query] = hubs.find.mock.calls[0] as [
      { where: { id: { value: string[] } } },
    ];
    expect(query.where.id.value).toEqual([HUB_A, HUB_B]);
  });

  it('con una central, solo esa y sus vuelos', async () => {
    const { service, flights } = build();
    await service.map(operator(), HUB_A);
    expect(flights.listFlights).toHaveBeenCalledWith(expect.anything(), HUB_A);
  });

  it('una central que no es suya responde 403', async () => {
    const { service, hubs } = build();
    await expect(service.map(operator(), HUB_C)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
    expect(hubs.find).not.toHaveBeenCalled();
  });
});
