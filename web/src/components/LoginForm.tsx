"use client";

import { useState, useSyncExternalStore, type FormEvent, type ReactNode } from "react";
import { BrandLockup, BrandMark } from "./BrandMark";
import { AlertIcon, ArrowRightIcon, EyeIcon, LockIcon, MailIcon, PinIcon } from "./icons";
import { PrimaryButton } from "./ui";

type Props = {
  onLogin: (email: string, password: string) => Promise<void>;
};

/**
 * El espacio aéreo de la entrada de la app (auth/widgets/airspace), en
 * corto: un plano inclinado con su retícula, un río y drones de la marca que
 * cruzan dejando su estela. Solo decoración.
 */
const TRAILS = ["M180 70 L 640 300", "M1300 60 L 1010 300"];
/** Filas cada vez más separadas hacia abajo, como un plano que se acerca. */
const GRID_ROWS = Array.from({ length: 9 }, (_, i) => Math.round(30 + 4.6 * i * i));
const GRID_COLUMNS = Array.from({ length: 17 }, (_, i) => -720 + i * 180);

const REDUCED = "(prefers-reduced-motion: reduce)";
function useReducedMotion(): boolean {
  return useSyncExternalStore(
    (notify) => {
      const query = window.matchMedia(REDUCED);
      query.addEventListener("change", notify);
      return () => query.removeEventListener("change", notify);
    },
    () => window.matchMedia(REDUCED).matches,
    () => true,
  );
}

function Airspace() {
  const still = useReducedMotion();
  return (
    <div
      aria-hidden
      className="pointer-events-none absolute inset-x-0 top-0 h-[44vh] min-h-[300px] overflow-hidden rounded-b-[40px] border-b border-white/10"
    >
      <div className="absolute inset-0 bg-[linear-gradient(180deg,#171e22,#0c1012)]" />
      <svg viewBox="0 0 1440 400" preserveAspectRatio="xMidYMid slice" className="absolute inset-0 size-full">
        {/* El plano inclinado, como el mapa del login: líneas hacia un punto de fuga. */}
        <g stroke="rgb(79 195 201 / 0.12)" strokeWidth={1.2}>
          {GRID_ROWS.map((y) => (
            <line key={`r${y}`} x1={0} x2={1440} y1={y} y2={y} />
          ))}
          {GRID_COLUMNS.map((x) => (
            <line key={`c${x}`} x1={720 + (x - 720) * 0.18} y1={-60} x2={x} y2={400} />
          ))}
        </g>
        <path
          d="M-40 150 C 260 230, 520 260, 760 210 S 1180 70, 1480 90"
          fill="none"
          stroke="rgb(166 180 186 / 0.16)"
          strokeWidth={46}
          strokeLinecap="round"
        />
        {TRAILS.map((trail, index) => (
          <g key={trail}>
            <path
              d={trail}
              stroke="rgb(79 195 201 / 0.55)"
              strokeWidth={3}
              strokeDasharray="10 14"
              fill="none"
            />
            {/* El dron recorre su estela; con "reducir movimiento" queda al inicio. */}
            <g transform={still ? `translate(${trail.split(" ").slice(0, 2).join(" ").slice(1)})` : undefined}>
              {!still && (
                <animateMotion
                  dur={index ? "11s" : "9s"}
                  begin={index ? "-4s" : "0s"}
                  repeatCount="indefinite"
                  rotate="auto"
                  path={trail}
                />
              )}
              <g transform="rotate(90)" style={{ filter: "drop-shadow(0 0 10px rgb(79 195 201 / 0.6))" }}>
                <BrandMark size={index ? 30 : 36} x={index ? -15 : -18} y={index ? -15 : -18} />
              </g>
            </g>
          </g>
        ))}
      </svg>
      {/* Velo arriba para que la marca se lea sobre el plano. */}
      <div className="absolute inset-x-0 top-0 h-28 bg-linear-to-b from-[#0b0e10]/70 to-transparent" />
    </div>
  );
}

function Field({
  label,
  icon,
  trailing,
  children,
}: {
  label: string;
  icon: ReactNode;
  trailing?: ReactNode;
  children: ReactNode;
}) {
  return (
    <label className="block">
      <span className="eyebrow !text-text/80">{label}</span>
      <span className="group mt-2 flex h-[52px] items-center gap-3 rounded-2xl border border-white/9 bg-white/4 px-4 transition focus-within:border-accent focus-within:ring-[1.6px] focus-within:ring-accent">
        <span className="text-muted transition group-focus-within:text-accent">{icon}</span>
        {children}
        {trailing}
      </span>
    </label>
  );
}

export function LoginForm({ onLogin }: Props) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [visible, setVisible] = useState(false);
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

  const input =
    "h-full min-w-0 flex-1 bg-transparent text-[15px] tracking-[0.01em] outline-none placeholder:text-muted/80";

  return (
    <main className="app-backdrop relative flex min-h-dvh flex-col overflow-x-hidden">
      <Airspace />
      <header className="relative z-10 flex items-center justify-between px-5 pt-5 sm:px-7 sm:pt-6">
        <BrandLockup size={36} />
        <span className="glass flex h-9 items-center gap-1.5 rounded-full px-3 text-[13px] font-semibold">
          <PinIcon size={14} className="text-accent" />
          Valledupar
        </span>
      </header>

      <form
        onSubmit={submit}
        className="rise-in relative z-10 mx-auto mt-[calc(44vh-150px)] w-full max-w-[560px] flex-1 rounded-t-[32px] border-t-[0.5px] border-white/12 bg-[linear-gradient(180deg,#161c20,#0b0e10)] px-6 pb-10 pt-8 shadow-[0_-12px_40px_rgb(0_0_0/0.45)] sm:px-9"
      >
        <p className="eyebrow !text-accent">Consola de simulación</p>
        <h1 className="mt-2 text-[40px] font-semibold leading-[1.08] tracking-[-0.03em]">Inicia sesión</h1>
        <p className="mt-2 text-[15px] tracking-[0.01em] text-muted">
          Solo la cuenta del administrador entra al radar.
        </p>

        <div className="mt-7 space-y-5">
          <Field label="Correo electrónico" icon={<MailIcon size={19} />}>
            <input
              type="email"
              required
              autoComplete="username"
              placeholder="nombre@correo.com"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              className={input}
            />
          </Field>
          <Field
            label="Contraseña"
            icon={<LockIcon size={19} />}
            trailing={
              <button
                type="button"
                onClick={() => setVisible((value) => !value)}
                aria-label={visible ? "Ocultar la contraseña" : "Mostrar la contraseña"}
                aria-pressed={visible}
                className="text-muted transition hover:text-text focus-visible:outline-2 focus-visible:outline-accent"
              >
                <EyeIcon size={19} />
              </button>
            }
          >
            <input
              type={visible ? "text" : "password"}
              required
              autoComplete="current-password"
              placeholder="Tu contraseña"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className={input}
            />
          </Field>
        </div>

        {error && (
          <p
            role="alert"
            className="mt-5 flex items-start gap-2.5 rounded-2xl border border-danger/30 bg-danger/10 px-3.5 py-3 text-sm font-medium text-danger"
          >
            <AlertIcon size={18} className="mt-px shrink-0" />
            {error}
          </p>
        )}

        <PrimaryButton type="submit" busy={busy} className="mt-7 h-[58px] w-full text-base">
          {busy ? "Entrando…" : "Iniciar sesión"}
          {!busy && <ArrowRightIcon size={18} strokeWidth={2.2} />}
        </PrimaryButton>
        <p className="mt-5 text-center text-[15px] text-muted">
          ¿Ensayar sin backend?{" "}
          <a href="?demo=1" className="font-bold text-accent underline-offset-2 hover:underline">
            Ver demostración
          </a>
        </p>
      </form>
    </main>
  );
}
