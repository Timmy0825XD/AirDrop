"use client";

import { useCallback, useSyncExternalStore } from "react";
import { setMapTheme, type Theme } from "./theme";

const KEY = "airdrop-theme";
const listeners = new Set<() => void>();

/** El tema vigente: el que puso en `<html>` el script de arranque del layout. */
function current(): Theme {
  return document.documentElement.dataset.theme === "light" ? "light" : "dark";
}

function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

/**
 * Claro u oscuro, como en la app. Arranca en oscuro (se ve mejor en la TV);
 * la elección queda en este navegador. El `<html>` lleva `data-theme`, que
 * es lo que leen los tokens de globals.css.
 */
export function useTheme() {
  const theme = useSyncExternalStore(subscribe, current, () => "dark" as Theme);
  // El mapa lee sus colores en JS: van con el tema antes de montarse.
  setMapTheme(theme);

  const toggle = useCallback(() => {
    const next: Theme = current() === "dark" ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    try {
      localStorage.setItem(KEY, next);
    } catch {
      // Sin almacenamiento, el tema dura lo que dure la pestaña.
    }
    listeners.forEach((listener) => listener());
  }, []);

  return { theme, toggle };
}
