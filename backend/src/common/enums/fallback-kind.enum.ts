/**
 * RF-18: qué pasó cuando ningún dron de la central pudo salir.
 * `retry` espera un dron (solo programados), `hub` pasó el pedido a otra
 * central y `conventional` cierra con un traslado por tierra.
 */
export enum FallbackKind {
  RETRY = 'retry',
  HUB = 'hub',
  CONVENTIONAL = 'conventional',
}
