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
  const service = new OrderGeneratorService(
    { get: () => 'true' } as never,
    actors as never,
    ordersService as never,
    dispatch as never,
    timeline as never,
    users as never,
  );
  service.random = () => 0.5;
  return { service, ordersService, dispatch, timeline, users };
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
      { latitude: 10.47, longitude: -73.25 },
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
