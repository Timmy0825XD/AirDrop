import {
  ClockChange,
  ClockState,
  ClockView,
  changeClock,
  presentClock,
  realTimeState,
  simElapsedMs,
  simNowMs,
} from './clock.rules';

/**
 * RF-31: la hora de todo el sistema. Reemplaza a `new Date()` y a
 * `Date.now()` en las reglas de negocio. Hay uno solo en el proceso
 * (`simClock`), porque también lo leen las validaciones de los DTO, que no
 * pasan por el DI de Nest.
 *
 * No lo usan el JWT, los OTP, el bloqueo de login ni el consentimiento: eso
 * es seguridad y va en hora real.
 */
export class SimClock {
  private state: ClockState = realTimeState(Date.now());

  now(): Date {
    return new Date(this.nowMs());
  }

  nowMs(): number {
    return simNowMs(this.state, Date.now());
  }

  current(): ClockState {
    return { ...this.state };
  }

  view(): ClockView {
    return presentClock(this.state, Date.now());
  }

  change(change: ClockChange): ClockState {
    this.state = changeClock(this.state, change, Date.now());
    return this.current();
  }

  restore(state: ClockState): void {
    this.state = { ...state };
  }

  resetToRealTime(): ClockState {
    this.state = realTimeState(Date.now());
    return this.current();
  }

  /** El tiempo simulado que cabe en `realMs` reales (0 en pausa). */
  scale(realMs: number): number {
    return simElapsedMs(this.state, realMs);
  }

  /**
   * Corre `task` cada `intervalMs` **simulados**: a x8, un barrido de 1 min
   * corre cada 7,5 s reales; en pausa no corre. Revisa cada segundo real.
   * Si el reloj vuelve atrás (reinicio del escenario), cuenta desde ahí.
   */
  every(intervalMs: number, task: () => void): NodeJS.Timeout {
    let last = this.nowMs();
    const timer = setInterval(
      () => {
        const now = this.nowMs();
        if (now < last) {
          last = now;
          return;
        }
        if (now - last >= intervalMs) {
          last = now;
          task();
        }
      },
      Math.min(1_000, intervalMs),
    );
    timer.unref();
    return timer;
  }
}

export const simClock = new SimClock();
