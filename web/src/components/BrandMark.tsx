import { useId } from "react";
import { BRAND_ROTOR_TURN, BRAND_ROTORS, BRAND_WORDMARK } from "@/lib/brand-shape";

/**
 * El ícono de AirDrop (Dron-cruz): la ficha con el degradado turquesa →
 * petróleo, el dron visto desde arriba y la cruz de salud encima. Por debajo
 * de 48 px el manual de marca pide la versión simple (ficha y cruz), porque los
 * trazos del dron ya no se ven.
 */
export function BrandMark({ size = 32, className = "" }: { size?: number; className?: string }) {
  const gradient = useId();
  const full = size >= 48;
  return (
    <svg viewBox="0 0 1024 1024" width={size} height={size} aria-hidden className={`shrink-0 ${className}`}>
      <defs>
        <linearGradient id={gradient} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" style={{ stopColor: "var(--brand-teal)" }} />
          <stop offset="1" style={{ stopColor: "var(--brand-petrol)" }} />
        </linearGradient>
      </defs>
      <rect width="1024" height="1024" rx="229" fill={`url(#${gradient})`} />
      {full ? (
        <>
          <g stroke="var(--brand-mist)" strokeWidth="20" strokeLinecap="round" fill="none">
            {BRAND_ROTORS.map(([x, y]) => (
              <line key={`arm-${x}-${y}`} x1="512" y1="512" x2={x} y2={y} />
            ))}
            {BRAND_ROTORS.map(([x, y], i) => (
              <circle
                key={`rotor-${x}-${y}`}
                cx={x}
                cy={y}
                r="72"
                strokeDasharray="170 56"
                transform={`rotate(${BRAND_ROTOR_TURN[i]} ${x} ${y})`}
              />
            ))}
          </g>
          <g fill="var(--brand-mist)">
            {BRAND_ROTORS.map(([x, y]) => (
              <circle key={`hub-${x}-${y}`} cx={x} cy={y} r="18" />
            ))}
          </g>
          <Cross />
        </>
      ) : (
        <g transform="translate(512 512) scale(1.22) translate(-512 -512)">
          <Cross />
        </g>
      )}
    </svg>
  );
}

function Cross() {
  return (
    <g fill="var(--brand-cross)">
      <rect x="444" y="322" width="136" height="380" rx="38" />
      <rect x="322" y="444" width="380" height="136" rx="38" />
    </g>
  );
}

/**
 * El logo horizontal: ícono y wordmark contorneado (Figtree ExtraBold, nunca
 * reescrito en otra fuente). Las proporciones son las del manual: las
 * mayúsculas miden el 42 % del ícono y el espacio entre ambos, el 26 %. Si se
 * pide, lo que es esta pantalla va al lado, separado por una línea.
 */
export function Wordmark({ size = 32, caption }: { size?: number; caption?: string }) {
  // El viewBox deja el centro de las mayúsculas en el centro vertical, así el
  // nombre queda alineado con el ícono aunque la "p" baje de la línea base.
  const height = size * 0.66;
  return (
    <div className="flex min-w-0 items-center" style={{ gap: size * 0.26 }}>
      <BrandMark size={size} />
      <svg
        viewBox="7.6 -900 3454 1100"
        height={height}
        width={(height * 3454) / 1100}
        role="img"
        aria-label="AirDrop"
        className="shrink-0 text-text"
      >
        <path d={BRAND_WORDMARK} fill="currentColor" />
      </svg>
      {caption && (
        <span className="ml-1 hidden truncate border-l border-line pl-2.5 text-[13px] text-muted lg:inline">
          {caption}
        </span>
      )}
    </div>
  );
}
