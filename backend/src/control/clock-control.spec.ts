import { NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { changeClock, realTimeState } from '../common/clock/clock.rules';
import { simClock } from '../common/clock/sim-clock';
import { TelemetryPublisher } from '../telemetry/telemetry.publisher';
import { TelemetryRedis } from '../telemetry/telemetry.redis';
import { ClockControlService } from './clock-control.service';
import { ControlEnabledGuard } from './control-enabled.guard';
import { CLOCK_STATE_KEY, isControlEnabled } from './control.rules';

const NOW = new Date('2026-11-05T15:00:00.000Z');

function build(enabled: string | undefined, saved: string | null = null) {
  const config = { get: jest.fn().mockReturnValue(enabled) };
  const redis = {
    read: jest.fn().mockResolvedValue(saved),
    write: jest.fn().mockResolvedValue(undefined),
  };
  const publisher = { publish: jest.fn().mockResolvedValue(undefined) };
  const service = new ClockControlService(
    config as unknown as ConfigService,
    redis as unknown as TelemetryRedis,
    publisher as unknown as TelemetryPublisher,
  );
  return { service, config, redis, publisher };
}

describe('consola de simulación: reloj (RF-31, RF-40)', () => {
  beforeEach(() => {
    jest.useFakeTimers({ now: NOW });
  });

  afterEach(() => {
    simClock.resetToRealTime();
    jest.useRealTimers();
  });

  it('solo se enciende con CONTROL_ENABLED=true', () => {
    expect(isControlEnabled('true')).toBe(true);
    expect(isControlEnabled(' TRUE ')).toBe(true);
    expect(isControlEnabled(undefined)).toBe(false);
    expect(isControlEnabled('1')).toBe(false);
  });

  it('con la consola apagada, /control/* responde 404', () => {
    const guard = new ControlEnabledGuard({
      get: () => undefined,
    } as unknown as ConfigService);
    expect(() => guard.canActivate()).toThrow(NotFoundException);
  });

  it('cambiar la velocidad la guarda en Redis y la publica por el socket', async () => {
    const { service, redis, publisher } = build('true');

    const view = await service.change({ speed: 8 });

    expect(view).toEqual({ now: NOW.toISOString(), speed: 8, paused: false });
    expect(redis.write).toHaveBeenCalledWith(
      CLOCK_STATE_KEY,
      expect.stringContaining('"speed":8'),
    );
    expect(publisher.publish).toHaveBeenCalledWith({
      type: 'clock',
      clock: view,
    });
  });

  it('al arrancar retoma el reloj guardado', async () => {
    const saved = changeClock(
      realTimeState(NOW.getTime()),
      { speed: 4 },
      NOW.getTime(),
    );
    const { service } = build('true', JSON.stringify(saved));

    await service.onModuleInit();

    expect(simClock.view().speed).toBe(4);
  });

  it('con la consola apagada arranca en hora real aunque haya un reloj guardado', async () => {
    const saved = changeClock(
      realTimeState(NOW.getTime()),
      { speed: 8 },
      NOW.getTime(),
    );
    const { service, redis } = build(undefined, JSON.stringify(saved));

    await service.onModuleInit();

    expect(redis.read).not.toHaveBeenCalled();
    expect(simClock.view()).toEqual({
      now: NOW.toISOString(),
      speed: 1,
      paused: false,
    });
  });
});
