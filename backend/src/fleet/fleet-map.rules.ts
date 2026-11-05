import { DroneStatus } from '../common/enums/drone-status.enum';
import { HubStatus } from '../common/enums/hub-status.enum';
import { HubType } from '../common/enums/hub-type.enum';
import { countFleet } from '../radar/radar.rules';

type MapHub = {
  id: string;
  name: string;
  type: HubType;
  status: HubStatus;
  latitude: number;
  longitude: number;
};

/**
 * Una central en el mapa del operador: dónde está, si opera y cómo va su
 * flota. Sin dirección, contactos, inventario ni cola: no son de su trabajo.
 */
export function presentMapHub(
  hub: MapHub,
  drones: Array<{ hubId: string; status: DroneStatus }>,
) {
  return {
    id: hub.id,
    name: hub.name,
    type: hub.type,
    status: hub.status,
    latitude: hub.latitude,
    longitude: hub.longitude,
    fleet: countFleet(drones.filter((drone) => drone.hubId === hub.id)),
  };
}
