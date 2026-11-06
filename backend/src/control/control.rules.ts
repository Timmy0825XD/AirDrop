export const CONTROL_DISABLED = 'La consola de simulación está apagada.';

/** RF-40: la consola existe solo si el backend arranca con `CONTROL_ENABLED=true`. */
export function isControlEnabled(raw: string | undefined): boolean {
  return raw?.trim().toLowerCase() === 'true';
}

export const CLOCK_STATE_KEY = 'control:clock';
