import type { ReactNode } from "react";
import { CloseIcon } from "./icons";

/** Piezas pequeñas compartidas por los paneles, con el vidrio de la app. */

export type Tone = "neutral" | "good" | "warn" | "bad" | "info";

/** Texto y punto de cada tono, como `StatusPill` en la app. */
export const TONE_TEXT: Record<Tone, string> = {
  neutral: "text-muted",
  good: "text-success",
  warn: "text-warning",
  bad: "text-danger",
  info: "text-accent",
};

const TONE_PILL: Record<Tone, string> = {
  neutral: "border-glass-border bg-glass text-muted",
  good: "border-success/35 bg-success/12 text-success",
  warn: "border-warning/35 bg-warning/12 text-warning",
  bad: "border-danger/35 bg-danger/12 text-danger",
  info: "border-accent/35 bg-accent/12 text-accent",
};

/** Estado en una pastilla con punto (Activa, En vuelo…). */
export function Pill({
  tone = "neutral",
  icon,
  children,
}: {
  tone?: Tone;
  icon?: ReactNode;
  children: ReactNode;
}) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 whitespace-nowrap rounded-full border px-2.5 py-1 text-xs font-semibold ${TONE_PILL[tone]}`}
    >
      {icon ?? <span className="size-1.5 rounded-full bg-current" />}
      {children}
    </span>
  );
}

/** Una cifra con su etiqueta, como `MetricTile` en la app. */
export function Stat({
  label,
  value,
  unit,
  icon,
  tone,
}: {
  label: string;
  value: ReactNode;
  unit?: string;
  icon?: ReactNode;
  tone?: Tone;
}) {
  return (
    <div className="rounded-2xl border border-glass-border bg-glass p-3">
      <div className="flex items-center gap-1.5 text-muted">
        {icon}
        <span className="eyebrow truncate !tracking-[0.1em]">{label}</span>
      </div>
      <div
        className={`mt-2 text-xl font-semibold leading-none tracking-tight tabular-nums ${tone ? TONE_TEXT[tone] : "text-text"}`}
      >
        {value}
        {unit && <span className="ml-1 text-xs font-medium text-muted">{unit}</span>}
      </div>
    </div>
  );
}

export function Section({
  title,
  icon,
  aside,
  children,
}: {
  title: string;
  icon?: ReactNode;
  aside?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="px-5 py-4">
      <div className="mb-3 flex items-center justify-between gap-3">
        <h3 className="eyebrow flex items-center gap-2">
          {icon && <span className="text-accent">{icon}</span>}
          {title}
        </h3>
        {aside}
      </div>
      {children}
    </section>
  );
}

/** Mosaico de ícono, como `GlassIconButton` activo de la app. */
export function IconTile({
  children,
  tone = "info",
  size = "md",
}: {
  children: ReactNode;
  tone?: Tone;
  size?: "sm" | "md";
}) {
  const box = size === "md" ? "size-12 rounded-[15px]" : "size-9 rounded-xl";
  const fill =
    tone === "info"
      ? "bg-accent-gradient text-on-accent shadow-[0_8px_24px_-6px_var(--accent-glow)]"
      : `border border-glass-border bg-glass ${TONE_TEXT[tone]}`;
  return <span className={`grid shrink-0 place-items-center ${box} ${fill}`}>{children}</span>;
}

export function GlassButton({
  label,
  onClick,
  children,
  pressed,
  className = "",
}: {
  label: string;
  onClick: () => void;
  children: ReactNode;
  pressed?: boolean;
  className?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={label}
      aria-pressed={pressed}
      title={label}
      className={`grid size-10 shrink-0 place-items-center rounded-[13px] border border-glass-border bg-glass text-text transition hover:bg-white/12 active:scale-95 focus-visible:outline-2 focus-visible:outline-accent ${className}`}
    >
      {children}
    </button>
  );
}

export function PanelShell({
  title,
  subtitle,
  icon,
  badge,
  onClose,
  children,
}: {
  title: string;
  subtitle?: string;
  icon?: ReactNode;
  badge?: ReactNode;
  onClose: () => void;
  children: ReactNode;
}) {
  return (
    <aside
      aria-label={title}
      className="panel-enter glass absolute inset-x-3 bottom-3 top-[124px] z-20 flex flex-col overflow-hidden rounded-[28px] sm:inset-x-auto sm:bottom-4 sm:right-4 sm:top-[96px] sm:w-[400px]"
    >
      <header className="flex items-start gap-3.5 px-5 pb-4 pt-5">
        {icon}
        <div className="min-w-0 flex-1">
          <h2 className="truncate text-xl font-semibold leading-tight tracking-tight">{title}</h2>
          {subtitle && <p className="mt-0.5 truncate text-sm text-muted">{subtitle}</p>}
        </div>
        <GlassButton label="Cerrar panel" onClick={onClose} className="size-9 rounded-xl">
          <CloseIcon size={16} />
        </GlassButton>
      </header>
      {badge && <div className="flex flex-wrap gap-1.5 px-5 pb-4">{badge}</div>}
      <div className="h-px bg-glass-border" />
      <div className="min-h-0 flex-1 divide-y divide-glass-border overflow-y-auto overscroll-contain">
        {children}
      </div>
    </aside>
  );
}

/** Cargando (con su rueda) o el error tal como lo manda Nest. */
export function PanelMessage({ failed, children }: { failed?: boolean; children: ReactNode }) {
  return (
    <div
      role={failed ? "alert" : "status"}
      className={`flex flex-col items-center gap-3 px-5 py-12 text-center text-sm ${failed ? "text-danger" : "text-muted"}`}
    >
      {!failed && (
        <span className="size-6 animate-spin rounded-full border-2 border-glass-border border-t-accent motion-reduce:animate-none" />
      )}
      {children}
    </div>
  );
}
