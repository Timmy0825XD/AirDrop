import { LngLat, PlannedCorridor, haversineKm } from '../routing/routing.rules';

/**
 * RF-46: altura y terreno (`context/operacion/condiciones-de-vuelo.md`). El
 * dron sigue el terreno a 90 m AGL, nunca pasa de 120 m AGL y la energía de
 * cada metro de ascenso neto entra en el consumo.
 */

/** Altura de crucero objetivo sobre el terreno. */
export const CRUISE_AGL_M = 90;
/** Techo legal con margen: el RAC 100 da 122 m (400 ft). */
export const MAX_AGL_M = 120;
/** Piso: el dron nunca baja de aquí sobre el terreno. */
export const MIN_AGL_M = 60;
/** La ruta se muestrea cada 250 m. */
export const PROFILE_SAMPLE_KM = 0.25;
/** Eficiencia del motor al subir: la mitad de la energía va a ganar altura. */
export const CLIMB_EFFICIENCY = 0.5;

export const CEILING_TOO_LOW =
  'El punto más alto de la ruta, con la altura de vuelo, supera el techo de este tipo de dron.';

export type TerrainGrid = {
  south: number;
  west: number;
  cellDeg: number;
  rows: number;
  cols: number;
  /** Fila a fila desde el sur: la elevación máxima de cada celda, en m. */
  maxElevationM: number[];
};

export type ProfileSample = {
  /** Km recorridos desde el inicio del corredor. */
  km: number;
  groundM: number;
  /** Altitud de vuelo sobre el nivel del mar. */
  altitudeMslM: number;
};

export type TerrainProfile = {
  samples: ProfileSample[];
  /** Metros que el dron sube en crucero, sumando solo los tramos de subida. */
  climbM: number;
  /** El punto más alto del vuelo sobre el nivel del mar. */
  peakMslM: number;
};

/** La elevación de la celda que contiene el punto; fuera de la malla, la del borde. */
export function groundAt(grid: TerrainGrid, point: LngLat): number {
  const row = clamp(
    Math.floor((point.latitude - grid.south) / grid.cellDeg),
    0,
    grid.rows - 1,
  );
  const col = clamp(
    Math.floor((point.longitude - grid.west) / grid.cellDeg),
    0,
    grid.cols - 1,
  );
  return grid.maxElevationM[row * grid.cols + col];
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

/**
 * Cuántos metros puede subir el dron por km recorrido en crucero, con su
 * velocidad vertical y su crucero: m/s × s por km.
 */
export function maxClimbPerKm(model: {
  verticalSpeedMs: number;
  maxSpeedKmh: number;
}): number {
  return model.maxSpeedKmh > 0
    ? (model.verticalSpeedMs * 3600) / model.maxSpeedKmh
    : Infinity;
}

/**
 * El perfil vertical del corredor. El dron arranca a 90 m AGL y **mantiene
 * la altitud** mientras quede entre 60 y 120 m sobre el terreno: no baja a
 * cada hondonada para volver a subir. Cuando la banda lo obliga (el terreno
 * sube o baja demasiado), vuelve a 90 m AGL. Como no sube más rápido que su
 * velocidad vertical, empieza a subir antes de una ladera (pasada de atrás
 * hacia adelante), sin pasar de 120 m AGL. El piso de 60 m manda siempre.
 */
export function terrainProfile(
  grid: TerrainGrid,
  corridor: Pick<PlannedCorridor, 'coordinates'>,
  model: { verticalSpeedMs: number; maxSpeedKmh: number },
): TerrainProfile {
  const points = samplePath(corridor.coordinates);
  const ground = points.map((sample) => groundAt(grid, sample.point));
  const climbPerSample = maxClimbPerKm(model) * PROFILE_SAMPLE_KM;
  const altitude: number[] = [];
  for (let index = 0; index < ground.length; index += 1) {
    const previous = index ? altitude[index - 1] : ground[0] + CRUISE_AGL_M;
    // Solo lo justo para volver a la banda: subir hasta el piso o bajar
    // hasta el techo. Así no gasta en subir lo que la siguiente hondonada
    // le haría bajar.
    altitude.push(
      Math.min(
        Math.max(previous, ground[index] + MIN_AGL_M),
        ground[index] + MAX_AGL_M,
      ),
    );
  }
  for (let index = altitude.length - 2; index >= 0; index -= 1) {
    const needed = altitude[index + 1] - climbPerSample;
    if (altitude[index] < needed) {
      altitude[index] = Math.min(needed, ground[index] + MAX_AGL_M);
    }
  }
  for (let index = 0; index < altitude.length; index += 1) {
    altitude[index] = Math.max(altitude[index], ground[index] + MIN_AGL_M);
  }
  let climbM = 0;
  for (let index = 1; index < altitude.length; index += 1) {
    climbM += Math.max(0, altitude[index] - altitude[index - 1]);
  }
  return {
    samples: points.map((sample, index) => ({
      km: Math.round(sample.km * 1000) / 1000,
      groundM: ground[index],
      altitudeMslM: Math.round(altitude[index]),
    })),
    climbM: Math.round(climbM),
    peakMslM: Math.round(Math.max(...altitude)),
  };
}

function samplePath(
  coordinates: Array<[number, number]>,
): Array<{ km: number; point: LngLat }> {
  const samples: Array<{ km: number; point: LngLat }> = [];
  let walked = 0;
  for (let index = 1; index < coordinates.length; index += 1) {
    const start = toLngLat(coordinates[index - 1]);
    const end = toLngLat(coordinates[index]);
    const segmentKm = haversineKm(start, end);
    const steps = Math.max(1, Math.ceil(segmentKm / PROFILE_SAMPLE_KM));
    for (let step = 0; step < steps; step += 1) {
      const ratio = step / steps;
      samples.push({
        km: walked + segmentKm * ratio,
        point: {
          longitude:
            start.longitude + (end.longitude - start.longitude) * ratio,
          latitude: start.latitude + (end.latitude - start.latitude) * ratio,
        },
      });
    }
    walked += segmentKm;
  }
  const last = coordinates.at(-1);
  if (last) {
    samples.push({ km: walked, point: toLngLat(last) });
  }
  return samples;
}

function toLngLat(pair: [number, number]): LngLat {
  return { longitude: pair[0], latitude: pair[1] };
}

/**
 * Batería que cuesta subir un metro: energía potencial de la masa máxima al
 * despegue, con la eficiencia del motor, sobre la energía de la batería.
 * Garza: 18 kg × 9,81 × 100 m / 3.600 / 0,5 ≈ 9,8 Wh ≈ 0,65 % de 1.500 Wh.
 */
export function climbPercentPerM(model: {
  mtowKg?: number | null;
  batteryWh?: number | null;
}): number {
  // Sin masa o sin batería conocidas, subir no se cobra (filas de antes).
  if (!model.batteryWh || !model.mtowKg || model.batteryWh <= 0) {
    return 0;
  }
  const wh = (model.mtowKg * 9.81) / 3600 / CLIMB_EFFICIENCY;
  return (wh / model.batteryWh) * 100;
}

/** La altitud de vuelo a `km` del inicio, interpolando entre muestras. */
export function altitudeAt(profile: TerrainProfile, km: number): ProfileSample {
  const samples = profile.samples;
  if (!samples.length) {
    return { km, groundM: 0, altitudeMslM: CRUISE_AGL_M };
  }
  if (km <= samples[0].km) {
    return samples[0];
  }
  for (let index = 1; index < samples.length; index += 1) {
    const next = samples[index];
    if (km <= next.km) {
      const prev = samples[index - 1];
      const span = next.km - prev.km || 1;
      const ratio = (km - prev.km) / span;
      return {
        km,
        groundM: Math.round(
          prev.groundM + (next.groundM - prev.groundM) * ratio,
        ),
        altitudeMslM:
          prev.altitudeMslM + (next.altitudeMslM - prev.altitudeMslM) * ratio,
      };
    }
  }
  return samples[samples.length - 1];
}
