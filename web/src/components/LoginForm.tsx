"use client";

import { useState, type FormEvent } from "react";

type Props = {
  onLogin: (email: string, password: string) => Promise<void>;
};

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
    "w-full rounded-xl border border-line bg-panel-2 px-4 py-3 text-sm outline-none transition focus:border-hub";

  return (
    <main className="grid min-h-dvh place-items-center bg-[radial-gradient(ellipse_at_top,#0f3330,transparent_60%)] p-4">
      <form
        onSubmit={submit}
        className="w-full max-w-sm space-y-4 rounded-2xl border border-line bg-panel/90 p-7 shadow-2xl backdrop-blur"
      >
        <div className="text-center">
          <h1 className="text-2xl font-semibold">AirDrop Radar</h1>
          <p className="mt-1 text-sm text-muted">Ecosistema de drones en tiempo real</p>
        </div>
        <label className="block space-y-1.5">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-muted">Correo</span>
          <input
            type="email"
            required
            autoComplete="username"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            className={field}
          />
        </label>
        <label className="block space-y-1.5">
          <span className="text-[11px] font-semibold uppercase tracking-wider text-muted">Contraseña</span>
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
          <p role="alert" className="rounded-lg bg-alert/10 px-3 py-2 text-sm text-alert">
            {error}
          </p>
        )}
        <button
          type="submit"
          disabled={busy}
          className="w-full rounded-xl bg-outbound py-3 text-sm font-semibold text-ink transition hover:brightness-110 disabled:opacity-60 focus-visible:outline-2 focus-visible:outline-white"
        >
          {busy ? "Entrando…" : "Entrar"}
        </button>
        <p className="text-center text-xs text-muted">
          Solo para el administrador ·{" "}
          <a href="?demo=1" className="text-hub underline-offset-2 hover:underline">
            ver demostración
          </a>
        </p>
      </form>
    </main>
  );
}
