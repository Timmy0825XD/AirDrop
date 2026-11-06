/** RF-34: qué hace el dron después de un incidente. */
export enum ContingencyProtocol {
  /** Sigue su misión, con alerta. De regreso, seguir es llegar a la central. */
  CONTINUE = 'continue',
  /** Vuelve a la central con el paquete. */
  RETURN_TO_HUB = 'return_to_hub',
  /** Baja en el punto más cercano fuera de toda geovalla y tormenta. */
  EMERGENCY_LANDING = 'emergency_landing',
}
