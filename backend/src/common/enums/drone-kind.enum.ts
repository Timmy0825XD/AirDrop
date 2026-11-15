/** RF-49: los tres tipos de dron de `context/operacion/flota.md`. */
export enum DroneKind {
  /** Colibrí: urgencias, llega antes y más lejos. */
  RAPID = 'rapid',
  /** Garza: dispensación y Sierra; el techo más alto. */
  BALANCED = 'balanced',
  /** Cóndor: reabastece ESE cercanas a su nodo. */
  CARGO = 'cargo',
}
