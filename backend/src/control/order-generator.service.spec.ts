import {
  deliveryPointsStub,
  TEST_POINT,
} from '../delivery-points/delivery-points.testing';
import { NO_POINT_IN_CIRCLE } from '../delivery-points/delivery-points.rules';
import { BadRequestException } from '@nestjs/common';
import { SaleType } from '../common/enums/sale-type.enum';
import { DESTINATION_IN_GEOFENCE } from '../routing/routing.rules';
import { simulatedRequesters } from './demo-scenario';
import { OrderGeneratorService } from './order-generator.service';
import { NO_SIMULATED_DESTINATION } from './sim-actors.rules';

function build(orderFlow = false) {
  const accounts = simulatedRequesters.map((person, index) => ({
    id: `sim-${index}`,
    email: person.email,
    simulated: true,
  }));
  const users = {
    find: jest.fn().mockResolvedValue(accounts),
    create: jest.fn((value: unknown) => value),
    save: jest.fn((value: unknown) => Promise.resolve(value)),
  };
  const ordersService = {
    catalog: jest.fn().mockResolvedValue([
      { name: 'Morfina 10 mg/mL', saleType: SaleType.PRESCRIPTION },
      { name: 'Acetaminofén 500 mg', saleType: SaleType.OVER_THE_COUNTER },
    ]),
    createEmergency: jest.fn().mockResolvedValue({ id: 'order-1' }),
    createPlan: jest.fn().mockResolvedValue({ id: 'plan-1' }),
  };
  const dispatch = { start: jest.fn().mockResolvedValue({}) };
  const timeline = { recordConsole: jest.fn().mockResolvedValue(undefined) };
  const actors = { view: () => ({ autoDispatcher: false, orderFlow }) };
  const points = deliveryPointsStub();
  const service = new OrderGeneratorService(
    { get: () => 'true' } as never,
    actors as never,
    ordersService as never,
    dispatch as never,
    timeline as never,
    users as never,
    points as never,
  );
  service.random = () => 0.5;
  return { service, ordersService, dispatch, timeline, users, points };
}

describe('OrderGeneratorService (RF-37)', () => {
  it('crea la urgencia con OrdersService, solo de venta libre, y la manda a la oferta escalonada', async () => {
    const { service, ordersService, dispatch } = build();
    const result = await service.generate('emergency');
    const [requester, dto] = ordersService.createEmergency.mock.calls[0] as [
      { simulated: boolean },
      { medicationName: string; saleType: SaleType },
    ];
    expect(requester.simulated).toBe(true);
    expect(dto.medicationName).toBe('Acetaminofén 500 mg');
    expect(dto.saleType).toBe(SaleType.OVER_THE_COUNTER);
    expect(dispatch.start).toHaveBeenCalledWith('order-1');
    expect(result.orderId).toBe('order-1');
    // RF-45: el destino es un punto de entrega activo, no un GPS suelto.
    expect(dto).toMatchObject({ deliveryPointId: TEST_POINT.id });
    expect(result.deliveryPointId).toBe(TEST_POINT.id);
  });

  it('el pico solo pide a puntos activos dentro del círculo (RF-36)', async () => {
    const { service, ordersService } = build();
    await expect(
      service.surge({ latitude: 10.0, longitude: -73.0 }, 1, 3),
    ).rejects.toThrow(NO_POINT_IN_CIRCLE);
    expect(ordersService.createEmergency).not.toHaveBeenCalled();
  });

  it('crea las cuentas simuladas que falten, marcadas como simuladas', async () => {
    const { service, users } = build();
    users.find.mockResolvedValue([]);
    await service.generate('emergency');
    expect(users.save).toHaveBeenCalledTimes(simulatedRequesters.length);
    expect(users.create).toHaveBeenCalledWith(
      expect.objectContaining({ simulated: true, documentNumber: null }),
    );
  });

  it('si el destino cae en una geovalla, prueba otro; después de 4 se rinde', async () => {
    const { service, ordersService } = build();
    ordersService.createEmergency.mockRejectedValue(
      new BadRequestException(DESTINATION_IN_GEOFENCE),
    );
    await expect(service.generate('emergency')).rejects.toThrow(
      NO_SIMULATED_DESTINATION,
    );
    expect(ordersService.createEmergency).toHaveBeenCalledTimes(4);
  });

  it('el pico cuenta las urgencias que el servicio no dejó crear, sin inventarlas', async () => {
    const { service, ordersService, timeline } = build();
    ordersService.createEmergency
      .mockResolvedValueOnce({ id: 'a' })
      .mockRejectedValueOnce(new BadRequestException('Sin stock.'))
      .mockResolvedValueOnce({ id: 'b' });
    const result = await service.surge(
      { latitude: TEST_POINT.latitude, longitude: TEST_POINT.longitude },
      1,
      3,
    );
    expect(result.created.map((order) => order.orderId)).toEqual(['a', 'b']);
    expect(result.failures).toEqual(['Sin stock.']);
    expect(timeline.recordConsole).toHaveBeenCalledWith(
      'Pico de urgencias: 2 de 3',
      'Sin crear: Sin stock.',
    );
  });

  it('el flujo continuo solo crea pedidos encendido', async () => {
    const off = build(false);
    await off.service.flowTick();
    expect(off.ordersService.createEmergency).not.toHaveBeenCalled();
    expect(off.ordersService.createPlan).not.toHaveBeenCalled();
    const on = build(true);
    on.service.random = () => 0.1; // < 70 %: urgencia
    await on.service.flowTick();
    expect(on.ordersService.createEmergency).toHaveBeenCalledTimes(1);
  });
});
