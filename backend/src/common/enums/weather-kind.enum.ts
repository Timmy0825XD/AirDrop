/** RF-32: los tres tipos de celda de clima simulado. */
export enum WeatherKind {
  /** Cambia la velocidad sobre el suelo y el consumo; sobre el límite no se vuela. */
  WIND = 'wind',
  /** Se vuela, con más consumo. */
  RAIN = 'rain',
  /** Zona no volable mientras dure: cuenta como geovalla para rutas. */
  STORM = 'storm',
}
