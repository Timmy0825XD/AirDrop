/**
 * RF-06 y RF-07: el papel de la central en la red regional
 * (`context/negocio/cobertura.md`). Solo un nodo tiene drones y despega.
 */
export enum HubNetworkRole {
  /** Drones, inventario y despachador: despega. */
  NODE = 'node',
  /** Empresa Social del Estado: inventario y despachador, sin drones. */
  ESE = 'ese',
}
