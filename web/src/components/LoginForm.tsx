"use client";

import { useState, type FormEvent } from "react";
import { AlertIcon, DroneIcon } from "./icons";

type Props = {
  onLogin: (email: string, password: string) => Promise<void>;
};

/** Anillos de radar detrás de la tarjeta: solo decoración. */
function RadarRings() {
  return (
    <div aria-hidden className="pointer-events-none absolute inset-0 grid place-items-center overflow-hidden">
      {[360, 560, 760, 960].map((size) => (
        <span
          key={size}
          className="absolute rounded-full border border-accent/10"
          style={{ width: size, height: size }}
        />
      ))}
    </div>
  );
}

export function LoginForm({ onLogin }: Props) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setBusy(true);
    try {
      await onLogin(email, password);
    } catch (failure) {
      setError(failure instanceof Error ? failure.message : "No se pudo iniciar sesión.");
      setBusy(false);
    }
  }

  const field =
    "w-full rounded-2xl border border-glass-border bg-glass px-4 py-3.5 text-[15px] outline-none transition placeholder:text-muted/70 focus:border-accent focus:ring-2 focus:ring-accent/25";

  return (
    <main className="app-backdrop relative grid min-h-dvh place-items-center p-4">
      <RadarRings />
      <form
        onSubmit={submit}
        className="glass rise-in relative w-full max-w-[400px] space-y-5 rounded-[28px] p-7 sm:p-8"
      >
        <div className="flex flex-col items-center text-center">
          <span className="grid size-16 place-items-center rounded-[20px] bg-accent-gradient text-on-accent shadow-[0_14px_36px_-10px_var(--accent-glow)]">
            <DroneIcon size={34} strokeWidth={1.9} />
          </span>
          <h1 className="mt-4 text-[28px] font-semibold leading-tight tracking-tight">AirDrop Radar</h1>
          <p className="mt-1 text-sm text-muted">Ecosistema de drones en tiempo real</p>
        </div>
        <label className="block space-y-2">
          <span className="eyebrow">Correo</span>
          <input
            type="email"
            required
            autoComplete="username"
            placeholder="correo@ejemplo.com"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            className={field}
          />
        </label>
        <label className="block space-y-2">
          <span className="eyebrow">Contraseña</span>
          <input
            type="password"
            required
            autoComplete="current-password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            className={field}
          />
        </label>
        {error && (
          <p
            role="alert"
            className="flex items-start gap-2.5 rounded-2xl border border-danger/30 bg-danger/10 px-3.5 py-3 text-sm font-medium text-danger"
          >
            <AlertIcon size={18} className="mt-px shrink-0" />
            {error}
          </p>
        )}
        <button
          type="submit"
          disabled={busy}
          className="flex h-[54px] w-full items-center justify-center gap-2 rounded-2xl bg-accent-gradient text-base font-bold text-on-accent shadow-[0_14px_36px_-12px_var(--accent-glow)] transition hover:brightness-110 active:scale-[0.98] disabled:opacity-60 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
        >
          {busy && (
            <span className="size-4 animate-spin rounded-full border-2 border-on-accent/30 border-t-on-accent motion-reduce:animate-none" />
          )}
          {busy ? "Entrando…" : "Entrar"}
        </button>
        <p className="text-center text-xs text-muted">
          Solo para el administrador ·{" "}
          <a href="?demo=1" className="font-semibold text-accent underline-offset-2 hover:underline">
            ver demostración
          </a>
        </p>
      </form>
    </main>
  );
}
