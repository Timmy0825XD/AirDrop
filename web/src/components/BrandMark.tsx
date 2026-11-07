/**
 * El dron de la marca visto desde arriba, como `DroneMark` de la app
 * (frontend/lib/core/widgets/drone_mark.dart): ala, fuselaje con cabina, dos
 * largueros con cuatro hélices y las luces de navegación (roja a la izquierda,
 * verde a la derecha). Misma grilla de 160 × 160. Con `spin`, las hélices
 * giran y las luces destellan; con "reducir movimiento" quedan quietas.
 */

const ROTORS: Array<[number, number]> = [
  [-36.5, -52],
  [36.5, -52],
  [-36.5, 52],
  [36.5, 52],
];

export function BrandMark({
  size = 40,
  spin = true,
  className = "",
  x,
  y,
}: {
  size?: number;
  spin?: boolean;
  className?: string;
  /** Dentro de otro SVG: dónde va la esquina. */
  x?: number;
  y?: number;
}) {
  return (
    <svg
      viewBox="-80 -80 160 160"
      width={size}
      height={size}
      x={x}
      y={y}
      aria-hidden
      className={`brand-mark shrink-0 ${spin ? "brand-mark-live" : ""} ${className}`}
    >
      {/* Ala, fuselaje, cabina y largueros. */}
      <rect x={-70} y={-6} width={140} height={12} rx={6} fill="var(--mark-wing)" />
      <rect x={-8} y={-40} width={16} height={80} rx={8} fill="var(--mark-body)" />
      <rect x={-4} y={-30} width={8} height={10} rx={3} fill="var(--accent)" opacity={0.7} />
      <rect x={-40} y={-52} width={7} height={104} rx={3.5} fill="var(--mark-boom)" />
      <rect x={33} y={-52} width={7} height={104} rx={3.5} fill="var(--mark-boom)" />
      {ROTORS.map(([x, y], index) => (
        <g key={index} transform={`translate(${x} ${y})`}>
          <circle r={17} fill="url(#brand-prop-glow)" />
          <g className={index % 2 ? "rotor-ccw" : "rotor-cw"}>
            <rect x={-15.5} y={-1.5} width={31} height={3} rx={1.5} fill="var(--mark-prop)" opacity={0.75} />
          </g>
        </g>
      ))}
      <g className="nav-light">
        <circle cx={-70} cy={0} r={9} fill="var(--danger)" opacity={0.3} />
        <circle cx={-70} cy={0} r={3.5} fill="var(--danger)" />
      </g>
      <g className="nav-light nav-light-late">
        <circle cx={70} cy={0} r={9} fill="var(--success)" opacity={0.3} />
        <circle cx={70} cy={0} r={3.5} fill="var(--success)" />
      </g>
      <defs>
        <radialGradient id="brand-prop-glow">
          <stop offset="0" stopColor="var(--mark-prop)" stopOpacity={0.3} />
          <stop offset="1" stopColor="var(--mark-prop)" stopOpacity={0} />
        </radialGradient>
      </defs>
    </svg>
  );
}

/** El símbolo con "AirDrop", como `AuthBrandBar` y el encabezado de la app. */
export function BrandLockup({ size = 34, subtitle }: { size?: number; subtitle?: string }) {
  return (
    <div className="flex min-w-0 items-center gap-2.5">
      <BrandMark size={size} />
      <div className="min-w-0 leading-none">
        <div className="text-[19px] font-semibold tracking-[-0.03em]">AirDrop</div>
        {subtitle && (
          <div className="mt-1 hidden truncate text-[11px] font-medium text-muted sm:block">
            {subtitle}
          </div>
        )}
      </div>
    </div>
  );
}
