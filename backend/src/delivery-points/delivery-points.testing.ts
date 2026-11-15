import { DeliveryPoint } from './delivery-point.entity';

/** Un punto de entrega de prueba: el puesto de salud de Badillo. */
export const TEST_POINT: DeliveryPoint = {
  id: '00000000-0000-4000-8000-0000000000d1',
  code: 'dp-badillo',
  name: 'Puesto de salud de Badillo',
  municipality: 'Valledupar',
  latitude: 10.6314,
  longitude: -73.1279,
  elevationM: 200,
  hubId: '00000000-0000-4000-8000-0000000000a1',
  active: true,
  coordinatedZoneCode: null,
  createdAt: new Date('2026-11-01T00:00:00.000Z'),
  updatedAt: new Date('2026-11-01T00:00:00.000Z'),
};

/** `DeliveryPointsService` para las pruebas de pedidos. */
export function deliveryPointsStub(point: DeliveryPoint = TEST_POINT) {
  return {
    requireForOrder: jest.fn().mockResolvedValue(point),
    available: jest.fn().mockResolvedValue([point]),
    syncScenario: jest.fn().mockResolvedValue(1),
  };
}
