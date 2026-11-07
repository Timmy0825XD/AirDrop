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

/**
 * Una cifra en una tarjeta de vidrio, como `MetricTile` en la app: la
 * etiqueta en mayúsculas arriba y el número grande debajo.
 */
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
    <div className="glass-card rounded-[20px] px-3.5 pb-3.5 pt-3">
      <div className="flex items-center gap-1.5 text-muted">
        {icon}
        <span className="eyebrow truncate !tracking-[0.12em]">{label}</span>
      </div>
      <div
        className={`mt-2 text-[26px] font-semibold leading-none tracking-[-0.03em] tabular-nums ${tone ? TONE_TEXT[tone] : "text-text"}`}
      >
        {value}
        {unit && <span className="ml-1 text-sm font-medium tracking-normal text-muted">{unit}</span>}
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

/**
 * Botón cuadrado de vidrio con un ícono, como `GlassIconButton` de la app:
 * 46 px, esquinas de un tercio del lado y sombra. Con `active` toma el
 * acento en degradado (encendido).
 */
export function GlassButton({
  label,
  onClick,
  children,
  pressed,
  active = false,
  disabled = false,
  className = "",
}: {
  label: string;
  onClick: () => void;
  children: ReactNode;
  pressed?: boolean;
  active?: boolean;
  disabled?: boolean;
  className?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={label}
      aria-pressed={pressed}
      title={label}
      disabled={disabled}
      className={`grid size-[46px] shrink-0 place-items-center rounded-[15px] border border-glass-border shadow-[0_8px_18px_-6px_var(--shadow)] transition active:scale-[0.92] disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-accent ${
        active ? "bg-accent-gradient text-on-accent" : "bg-bar text-text hover:bg-surface"
      } ${className}`}
    >
      {children}
    </button>
  );
}

/**
 * El botón principal de la app: cápsula con el acento en degradado y una
 * flecha. `tone="danger"` para lo que no se deshace (apagar una central).
 */
export function PrimaryButton({
  children,
  onClick,
  disabled,
  busy,
  tone = "accent",
  type = "button",
  className = "",
}: {
  children: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
  busy?: boolean;
  tone?: "accent" | "danger";
  type?: "button" | "submit";
  className?: string;
}) {
  const look =
    tone === "danger"
      ? "rounded-full border border-danger/45 bg-danger/15 text-danger hover:bg-danger/25"
      : "stadium hover:brightness-110";
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled || busy}
      className={`flex h-12 items-center justify-center gap-2 px-6 text-[15px] font-bold transition active:scale-[0.97] disabled:opacity-55 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent ${look} ${className}`}
    >
      {busy && (
        <span className="size-4 animate-spin rounded-full border-2 border-current/30 border-t-current motion-reduce:animate-none" />
      )}
      {children}
    </button>
  );
}

/** Chip redondo que se elige con un toque, como `ChoicePill` de la app. */
export function Chip({
  selected,
  onClick,
  children,
  icon,
  disabled,
}: {
  selected: boolean;
  onClick: () => void;
  children: ReactNode;
  icon?: ReactNode;
  disabled?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={selected}
      disabled={disabled}
      className={`flex h-10 items-center gap-1.5 rounded-full border px-3.5 text-sm font-semibold tabular-nums transition active:scale-95 disabled:opacity-50 focus-visible:outline-2 focus-visible:outline-accent ${
        selected
          ? "border-transparent bg-accent-gradient text-on-accent shadow-[0_6px_18px_-6px_var(--accent-glow)]"
          : "border-glass-border bg-glass text-text hover:bg-white/10"
      }`}
    >
      {icon}
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
          <h2 className="truncate text-[22px] font-semibold leading-[1.08] tracking-[-0.03em]">{title}</h2>
          {subtitle && <p className="mt-0.5 truncate text-sm text-muted">{subtitle}</p>}
        </div>
        <GlassButton label="Cerrar panel" onClick={onClose} className="!size-10 !rounded-[13px]">
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
