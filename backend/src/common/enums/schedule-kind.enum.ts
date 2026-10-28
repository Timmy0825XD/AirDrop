/** RU-30: cómo se arma el calendario de un plan. */
export enum ScheduleKind {
  /** Días de la semana, cada 1 a 4 semanas. */
  WEEKLY = 'weekly',
  /** Un día del mes. */
  MONTHLY = 'monthly',
  /** Fechas sueltas. */
  DATES = 'dates',
}
