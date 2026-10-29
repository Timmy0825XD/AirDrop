"use client";

import { useMemo, useSyncExternalStore } from "react";
import { demoSource } from "@/lib/demo";
import { useSession } from "@/lib/session";
import { liveSource } from "@/lib/source";
import { Dashboard } from "./Dashboard";
import { LoginForm } from "./LoginForm";

const SPLASH = (
  <main className="app-backdrop grid min-h-dvh place-items-center">
    <div role="status" className="flex flex-col items-center gap-4 text-sm text-muted">
      <span className="size-8 animate-spin rounded-full border-2 border-glass-border border-t-accent motion-reduce:animate-none" />
      Cargando…
    </div>
  </main>
);

const noSubscription = () => () => {};

/** `?demo=1` abre el simulador sin backend ni sesión. `null` en el servidor. */
function useDemoFlag(): boolean | null {
  return useSyncExternalStore(
    noSubscription,
    () => new URLSearchParams(window.location.search).has("demo"),
    () => null,
  );
}

function LiveRadar({ token, name, onLogout }: { token: string; name: string; onLogout: () => void }) {
  const source = useMemo(() => liveSource(token), [token]);
  return <Dashboard source={source} userName={name} onLogout={onLogout} />;
}

export function RadarApp() {
  const demo = useDemoFlag();
  const { session, ready, login, logout } = useSession();
  const simulated = useMemo(() => demoSource(), []);

  if (demo === null || !ready) return SPLASH;
  if (demo) return <Dashboard source={simulated} userName={null} onLogout={logout} />;
  if (!session) return <LoginForm onLogin={login} />;
  return <LiveRadar token={session.token} name={session.name} onLogout={logout} />;
}
