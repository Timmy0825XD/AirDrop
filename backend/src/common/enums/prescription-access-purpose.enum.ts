/** RF-51: para qué se abrió una fórmula. */
export enum PrescriptionAccessPurpose {
  /** El despachador la revisa para autorizar la salida. */
  AUTHORIZE = 'authorize',
  /** La central la consulta desde el histórico. */
  HISTORY = 'history',
  /** Para atender un reclamo o una auditoría. */
  CLAIM = 'claim',
}
