"use client";

import { useCallback, useEffect, useState } from "react";
import type { RadarSource } from "./source";
import type { DeliveryPoint } from "./types";

/**
 * Los puntos de entrega de la red (RF-45). No llegan por el socket: se leen
 * al abrir, al reiniciar el escenario (`resetKey`) y después de activar o
 * desactivar uno.
 */
export function useDeliveryPoints(source: RadarSource, resetKey: unknown) {
  const [points, setPoints] = useState<DeliveryPoint[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    try {
      setPoints(await source.deliveryPoints());
    } catch {
      // Sin puntos el radar sigue: el mapa solo no los dibuja.
      setPoints([]);
    }
  }, [source]);

  useEffect(() => {
    // La carga escribe el estado al terminar, no dentro del efecto.
    const timer = setTimeout(() => void load(), 0);
    return () => clearTimeout(timer);
  }, [load, resetKey]);

  /** Activa o desactiva un punto, como el apagón de una central. */
  const setActive = useCallback(
    async (id: string, active: boolean) => {
      setBusy(true);
      setError(null);
      try {
        await source.setPointActive(id, active);
        await load();
      } catch (reason) {
        setError(reason instanceof Error ? reason.message : "No se pudo cambiar el punto.");
      } finally {
        setBusy(false);
      }
    },
    [source, load],
  );

  const dismiss = useCallback(() => setError(null), []);

  return { points, error, busy, setActive, dismiss };
}
