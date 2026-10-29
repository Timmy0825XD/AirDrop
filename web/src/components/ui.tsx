import type { ReactNode } from "react";

/** Piezas pequeñas compartidas por los paneles. */

export function Pill({
  tone = "neutral",
  children,
}: {
  tone?: "neutral" | "good" | "warn" | "bad" | "info";
  children: ReactNode;
}) {
  const tones = {
    neutral: "bg-panel-2 text-muted",
    good: "bg-outbound/15 text-outbound",
    warn: "bg-returning/15 text-returning",
    bad: "bg-alert/15 text-alert",
    info: "bg-hub/15 text-hub",
  } as const;
  return (
    <span
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-[11px] font-semibold ${tones[tone]}`}
    >
      {children}
    </span>
  );
}

export function Stat({
  label,
  value,
  unit,
  tone,
}: {
  label: string;
  value: ReactNode;
  unit?: string;
  tone?: "bad" | "good";
}) {
  const color = tone === "bad" ? "text-alert" : tone === "good" ? "text-outbound" : "text-text";
  return (
    <div className="rounded-xl border border-line bg-panel-2/60 p-3">
      <div className="text-[10px] font-semibold uppercase tracking-wider text-muted">
        {label}
      </div>
      <div className={`mt-1 font-mono text-xl font-semibold leading-none ${color}`}>
        {value}
        {unit && <span className="ml-1 text-xs font-normal text-muted">{unit}</span>}
      </div>
    </div>
  );
}

export function Section({
  title,
  aside,
  children,
}: {
  title: string;
  aside?: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="border-t border-line px-5 py-4">
      <div className="mb-3 flex items-center justify-between">
        <h3 className="text-xs font-semibold uppercase tracking-wider text-muted">
          {title}
        </h3>
        {aside}
      </div>
      {children}
    </section>
  );
}

export function PanelShell({
  title,
  subtitle,
  badge,
  onClose,
  children,
}: {
  title: string;
  subtitle?: string;
  badge?: ReactNode;
  onClose: () => void;
  children: ReactNode;
}) {
  return (
    <div
      role="complementary"
      aria-label={title}
      className="panel-enter absolute inset-x-0 bottom-0 top-16 z-20 flex max-h-[calc(100%-4rem)] flex-col overflow-hidden border-l border-line bg-panel/95 shadow-2xl backdrop-blur-md sm:inset-x-auto sm:right-0 sm:w-[420px]"
    >
      <header className="flex items-start gap-3 px-5 py-4">
        <div className="min-w-0 flex-1">
          <h2 className="truncate text-lg font-semibold">{title}</h2>
          {subtitle && <p className="truncate text-sm text-muted">{subtitle}</p>}
          {badge && <div className="mt-2 flex flex-wrap gap-1.5">{badge}</div>}
        </div>
        <button
          type="button"
          onClick={onClose}
          aria-label="Cerrar panel"
          className="grid size-8 shrink-0 place-items-center rounded-lg border border-line text-muted transition hover:bg-panel-2 hover:text-text focus-visible:outline-2 focus-visible:outline-hub"
        >
          ✕
        </button>
      </header>
      <div className="min-h-0 flex-1 overflow-y-auto">{children}</div>
    </div>
  );
}

export function PanelMessage({ children }: { children: ReactNode }) {
  return <p className="px-5 py-8 text-center text-sm text-muted">{children}</p>;
}
