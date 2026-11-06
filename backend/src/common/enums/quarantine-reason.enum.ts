/** Por qué un insumo devuelto no reingresa al inventario. */
export enum QuarantineReason {
  COLD_CHAIN = 'cold_chain',
  PACKAGING = 'packaging',
  /** RF-34: venía en una misión con incidente; no reingresa sin revisión. */
  INCIDENT = 'incident',
}
