import { simClock } from '../common/clock/sim-clock';
import { UnidentifiedContactsService } from './unidentified-contacts.service';

function build(corridors: Array<{ coordinates: number[][] }> = []) {
  const publisher = { publish: jest.fn().mockResolvedValue(undefined) };
  const timeline = {
    recordAlert: jest.fn().mockResolvedValue(undefined),
    recordConsole: jest.fn().mockResolvedValue(undefined),
  };
  const flights = {
    activeCorridors: jest.fn(() =>
      corridors.map((corridor, index) => ({
        orderId: `o${index}`,
        droneId: `d${index}`,
        identifier: `AD-SUR-0${index + 1}`,
        ...corridor,
      })),
    ),
  };
  const service = new UnidentifiedContactsService(
    { get: () => 'false' } as never,
    flights as never,
    publisher as never,
    timeline as never,
  );
  return { service, publisher, timeline };
}

describe('UnidentifiedContactsService (RF-36, RF-48)', () => {
  it('cruza, avisa una vez al acercarse a un corredor y desaparece al terminar', async () => {
    const corridor = {
      coordinates: [
        [-73.2, 10.3],
        [-73.2, 10.5],
      ],
    };
    const { service, publisher, timeline } = build([corridor]);
    const start = simClock.nowMs();
    const contact = await service.launch({
      durationMin: 10,
      from: { latitude: 10.4, longitude: -73.3 },
      to: { latitude: 10.4, longitude: -73.1 },
    });
    expect(publisher.publish).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'unidentified', action: 'started' }),
    );
    await service.move(start + 5 * 60_000);
    await service.move(start + 5 * 60_000 + 5_000);
    expect(timeline.recordAlert).toHaveBeenCalledTimes(1);
    expect(service.list()[0].id).toBe(contact.id);
    await service.move(start + 11 * 60_000);
    expect(service.list()).toEqual([]);
    expect(publisher.publish).toHaveBeenLastCalledWith(
      expect.objectContaining({ action: 'ended' }),
    );
  });

  it('desde la consola queda en la línea de tiempo; el reinicio lo borra', async () => {
    const { service, timeline } = build();
    await service.launchFromConsole({ durationMin: 5 });
    expect(timeline.recordConsole).toHaveBeenCalledWith(
      'Dron no identificado',
      expect.stringContaining('5 min'),
    );
    await service.clear();
    expect(service.list()).toEqual([]);
  });
});
