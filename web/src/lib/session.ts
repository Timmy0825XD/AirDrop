"use client";

import { useCallback, useMemo, useSyncExternalStore } from "react";
import { ApiError, login as loginRequest } from "./api";

const KEY = "airdrop.radar.session";

type Session = { token: string; name: string };

const listeners = new Set<() => void>();
/** Respaldo si el navegador bloquea `sessionStorage`. */
let memory: string | null = null;

function subscribe(listener: () => void) {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}

function snapshot(): string | null {
  try {
    return sessionStorage.getItem(KEY) ?? memory;
  } catch {
    return memory;
  }
}

function write(session: Session | null) {
  memory = session ? JSON.stringify(session) : null;
  try {
    if (memory) sessionStorage.setItem(KEY, memory);
    else sessionStorage.removeItem(KEY);
  } catch {
    // Sin almacenamiento: la sesión vive solo mientras la pestaña esté abierta.
  }
  listeners.forEach((listener) => listener());
}

/** La sesión del administrador. Vive en la pestaña, no en disco. */
export function useSession() {
  // En el servidor no hay sesión que leer: `undefined` significa "aún no sé".
  const raw = useSyncExternalStore(subscribe, snapshot, () => undefined);
  const session = useMemo<Session | null>(() => {
    if (!raw) return null;
    try {
      return JSON.parse(raw) as Session;
    } catch {
      return null;
    }
  }, [raw]);

  const login = useCallback(async (email: string, password: string) => {
    const result = await loginRequest(email, password);
    if (result.user.role !== "admin") {
      throw new ApiError("El radar es solo para el administrador.", 403);
    }
    write({ token: result.accessToken, name: result.user.fullName });
  }, []);

  const logout = useCallback(() => write(null), []);

  return { session, ready: raw !== undefined, login, logout };
}
