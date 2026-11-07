import { DRONE_BODY, DRONE_ROTOR_R, DRONE_ROTORS, DRONE_WINGS } from "@/lib/drone-shape";

/**
 * La marca de la consola: la silueta del dron de entrega, rellena, inclinada
 * hacia el noreste como si saliera de despacho. Quieta: es una firma, no una
 * animación.
 */
export function BrandMark({ size = 22, className = "" }: { size?: number; className?: string }) {
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} aria-hidden className={`shrink-0 ${className}`}>
      <g transform="rotate(35 12 12)" fill="currentColor">
        <path d={DRONE_BODY} />
        {DRONE_WINGS.map((wing) => (
          <path key={wing} d={wing} />
        ))}
        {DRONE_ROTORS.map(([cx, cy]) => (
          <circle key={cx} cx={cx} cy={cy} r={DRONE_ROTOR_R + 0.3} />
        ))}
      </g>
    </svg>
  );
}

/** La marca con "AirDrop" y, si se pide, lo que es esta pantalla. */
export function Wordmark({ caption }: { caption?: string }) {
  return (
    <div className="flex min-w-0 items-center gap-2.5">
      <BrandMark size={22} className="text-accent" />
      <span className="text-[17px] font-semibold tracking-[-0.02em]">AirDrop</span>
      {caption && (
        <span className="hidden truncate border-l border-line pl-2.5 text-[13px] text-muted lg:inline">
          {caption}
        </span>
      )}
    </div>
  );
}
