import type { ReactNode } from "react";
import { CloseIcon } from "./icons";

/**
 * Piezas compartidas de la consola. Un solo vocabulario: botones de 8 px de
 * radio, paneles de 12, líneas finas y cifras en mono. El color es estado.
 */

export type Tone = "neutral" | "good" | "warn" | "bad" | "info";

export const TONE_TEXT: Record<Tone, string> = {
  neutral: "text-muted",
  good: "text-success",
  warn: "text-warning",
  bad: "text-danger",
  info: "text-accent",
};

const TONE_BADGE: Record<Tone, string> = {
  neutral: "border-line-strong text-muted",
  good: "border-success/40 text-success",
  warn: "border-warning/45 text-warning",
  bad: "border-danger/45 text-danger",
  info: "border-accent/45 text-accent",
};

/** Un estado en una etiqueta chica con su punto (Activa, En vuelo…). */
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
      className={`inline-flex h-6 items-center gap-1.5 whitespace-nowrap rounded-md border px-2 text-[12px] font-medium ${TONE_BADGE[tone]}`}
    >
      {icon ?? <span className="size-1.5 rounded-full bg-current" />}
      {children}
    </span>
  );
}

/** Una cifra con su nombre arriba, sin caja: las cifras se leen en mono. */
export function Stat({
  label,
  value,
  unit,
  tone,
}: {
  label: string;
  value: ReactNode;
  unit?: string;
  /** Solo para el ícono de antes; la cifra no lo necesita. */
  icon?: ReactNode;
  tone?: Tone;
}) {
  return (
    <div className="min-w-0">
      <div className="truncate text-[12px] text-muted">{label}</div>
      <div
        className={`figures mt-1 truncate text-[22px] font-medium leading-none ${tone ? TONE_TEXT[tone] : "text-text"}`}
      >
        {value}
        {unit && <span className="ml-1 font-sans text-[13px] font-normal text-muted">{unit}</span>}
      </div>
    </div>
  );
}

/** Un bloque del panel: título corto y su contenido, separado por una línea. */
export function Section({
  title,
  aside,
  children,
}: {
  title: string;
  /** Ya no se pinta: los títulos se sostienen solos. */
  icon?: ReactNode;
  aside?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="px-5 py-5">
      <div className="mb-3.5 flex items-baseline justify-between gap-3">
        <h3 className="text-[14px] font-semibold text-text">{title}</h3>
        {aside}
      </div>
      {children}
    </section>
  );
}

/** Botón cuadrado con un ícono (cerrar, acercar…). `active` lo deja encendido. */
export function IconButton({
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
      className={`press grid size-10 shrink-0 place-items-center rounded-lg border disabled:opacity-40 ${
        active
          ? "border-accent/50 bg-accent/12 text-accent"
          : "border-line bg-panel text-muted hover:border-line-strong hover:bg-hover hover:text-text"
      } ${className}`}
    >
      {children}
    </button>
  );
}

/**
 * El botón de una acción. `primary` es la acción del lugar; `danger`, lo que
 * no se deshace (apagar una central); `quiet`, lo demás.
 */
export function Button({
  children,
  onClick,
  disabled,
  busy,
  tone = "primary",
  type = "button",
  className = "",
}: {
  children: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
  busy?: boolean;
  tone?: "primary" | "danger" | "quiet";
  type?: "button" | "submit";
  className?: string;
}) {
  const look = {
    primary: "border-transparent bg-accent text-on-accent hover:bg-accent-strong",
    danger: "border-danger/50 bg-danger/10 text-danger hover:bg-danger/18",
    quiet: "border-line-strong bg-raised text-text hover:bg-hover",
  }[tone];
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled || busy}
      aria-busy={busy || undefined}
      className={`press flex h-11 items-center justify-center gap-2 rounded-lg border px-4 text-[14px] font-semibold disabled:opacity-50 ${look} ${className}`}
    >
      {busy && (
        <span className="size-4 animate-spin rounded-full border-2 border-current/30 border-t-current motion-reduce:animate-none" />
      )}
      {children}
    </button>
  );
}

/** Una opción de un grupo (duración, intensidad…). */
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
      className={`press flex h-9 items-center justify-center gap-1.5 rounded-md border px-3 text-[13px] font-medium tabular-nums disabled:opacity-45 ${
        selected
          ? "border-accent/60 bg-accent/14 text-accent"
          : "border-line bg-panel text-muted hover:border-line-strong hover:text-text"
      }`}
    >
      {icon}
      {children}
    </button>
  );
}

/**
 * El inspector: la columna derecha del mapa con el detalle de lo elegido.
 * Encabezado con el nombre, sus estados y el contenido por bloques.
 */
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
      className="enter-side absolute inset-x-2 bottom-2 top-2 z-20 flex flex-col overflow-hidden rounded-xl border border-line bg-panel shadow-[0_18px_50px_-20px_var(--shadow)] sm:inset-x-auto sm:right-3 sm:top-3 sm:bottom-3 sm:w-[400px]"
    >
      <header className="flex items-start gap-3 px-5 pb-4 pt-5">
        {icon && <span className="mt-1 shrink-0 text-muted">{icon}</span>}
        <div className="min-w-0 flex-1">
          <h2 className="truncate text-[20px] font-semibold leading-tight tracking-[-0.015em]">
            {title}
          </h2>
          {subtitle && <p className="mt-1 truncate text-[13px] text-muted">{subtitle}</p>}
        </div>
        <IconButton label="Cerrar" onClick={onClose} className="!size-9">
          <CloseIcon size={16} />
        </IconButton>
      </header>
      {badge && <div className="flex flex-wrap gap-1.5 px-5 pb-4">{badge}</div>}
      <div className="min-h-0 flex-1 divide-y divide-line overflow-y-auto overscroll-contain border-t border-line">
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
      className={`flex flex-col items-center gap-3 px-5 py-12 text-center text-[14px] ${failed ? "text-danger" : "text-muted"}`}
    >
      {!failed && (
        <span className="size-5 animate-spin rounded-full border-2 border-line-strong border-t-accent motion-reduce:animate-none" />
      )}
      {children}
    </div>
  );
}

/** Un aviso dentro de un panel (cuarentena, sin energía…), con su tono. */
export function Note({ tone = "neutral", children }: { tone?: Tone; children: ReactNode }) {
  const look = {
    neutral: "border-line text-muted",
    good: "border-success/35 text-success",
    warn: "border-warning/40 text-warning",
    bad: "border-danger/40 text-danger",
    info: "border-accent/40 text-accent",
  }[tone];
  return <p className={`rounded-lg border bg-raised px-3.5 py-3 text-[13px] leading-snug ${look}`}>{children}</p>;
}
