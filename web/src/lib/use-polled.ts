"use client";

import { useEffect, useRef, useState } from "react";

type State<T> = { key: string | null; data: T | null; error: string | null };

/**
 * Carga `load` al elegir algo (`key`) y la repite cada `intervalMs`. Mientras
 * se recarga conserva lo último que llegó, para que el panel no parpadee.
 */
export function usePolled<T>(
  load: () => Promise<T>,
  key: string | null,
  intervalMs: number,
) {
  const [state, setState] = useState<State<T>>({ key: null, data: null, error: null });
  const loader = useRef(load);

  useEffect(() => {
    loader.current = load;
  });

  useEffect(() => {
    if (!key) return;
    let cancelled = false;
    const run = async () => {
      try {
        const data = await loader.current();
        if (!cancelled) setState({ key, data, error: null });
      } catch (error) {
        const message = error instanceof Error ? error.message : "No se pudo cargar.";
        if (!cancelled) {
          setState((current) => ({
            key,
            data: current.key === key ? current.data : null,
            error: message,
          }));
        }
      }
    };
    void run();
    const timer = setInterval(() => void run(), intervalMs);
    return () => {
      cancelled = true;
      clearInterval(timer);
    };
  }, [key, intervalMs]);

  return state.key === key ? state : { key, data: null as T | null, error: null };
}
