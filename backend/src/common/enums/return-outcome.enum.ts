/** Qué pasó con el paquete que volvió sin entregar (cuarentena de productos.md). */
export enum ReturnOutcome {
  RESTOCKED = 'restocked',
  QUARANTINED = 'quarantined',
  /** RF-34: se perdió con el dron (choque grave o dron perdido). */
  LOST = 'lost',
}
