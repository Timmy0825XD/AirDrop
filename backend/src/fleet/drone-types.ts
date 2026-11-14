import { DroneKind } from '../common/enums/drone-kind.enum';

/**
 * RF-49: las especificaciones de los tres tipos propios
 * (`context/operacion/flota.md` y `condiciones-de-vuelo.md`). Son modelos de
 * la simulación, con cifras dentro de los rangos públicos de los drones
 * médicos VTOL y de carga; la app no nombra un fabricante.
 */
export type DroneTypeSpec = {
  code: string;
  kind: DroneKind;
  name: string;
  maxPayloadKg: number;
  /** Crucero, en km/h. */
  maxSpeedKmh: number;
  /** Alcance total en crucero con la batería llena. */
  maxRangeKm: number;
  /** Techo de servicio sobre el nivel del mar. */
  ceilingM: number;
  verticalSpeedMs: number;
  mtowKg: number;
  batteryWh: number;
  windSustainedMs: number;
  windGustMs: number;
};

export const DRONE_TYPES: readonly DroneTypeSpec[] = [
  {
    code: 'rapid',
    kind: DroneKind.RAPID,
    name: 'Colibrí',
    maxPayloadKg: 2,
    maxSpeedKmh: 140,
    maxRangeKm: 120,
    ceilingM: 3500,
    verticalSpeedMs: 5,
    mtowKg: 9,
    batteryWh: 900,
    windSustainedMs: 12,
    windGustMs: 16,
  },
  {
    code: 'balanced',
    kind: DroneKind.BALANCED,
    name: 'Garza',
    maxPayloadKg: 5,
    maxSpeedKmh: 110,
    maxRangeKm: 90,
    ceilingM: 4000,
    verticalSpeedMs: 4,
    mtowKg: 18,
    batteryWh: 1500,
    windSustainedMs: 15,
    windGustMs: 20,
  },
  {
    code: 'cargo',
    kind: DroneKind.CARGO,
    name: 'Cóndor',
    maxPayloadKg: 15,
    maxSpeedKmh: 60,
    maxRangeKm: 30,
    ceilingM: 2500,
    verticalSpeedMs: 3,
    mtowKg: 45,
    batteryWh: 2000,
    windSustainedMs: 10,
    windGustMs: 14,
  },
];

/** RF-49: el compartimento de frío pesa 1 kg y se descuenta de la carga útil. */
export const COLD_COMPARTMENT_KG = 1;

/** Carga útil real del dron, con el compartimento de frío descontado. */
export function usablePayloadKg(
  maxPayloadKg: number,
  coldCompartment: boolean,
): number {
  return Math.max(
    0,
    maxPayloadKg - (coldCompartment ? COLD_COMPARTMENT_KG : 0),
  );
}
