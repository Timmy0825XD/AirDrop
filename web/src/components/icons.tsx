import type { ReactNode, SVGProps } from "react";
import { DRONE_BODY, DRONE_ROTOR_R, DRONE_ROTORS, DRONE_WINGS } from "@/lib/drone-shape";

/**
 * Íconos de la consola, dibujados a mano en una cuadrícula de 24 con un solo
 * trazo (1,6, puntas redondeadas) en `currentColor`. Un solo lugar para todos.
 */

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function Icon({ size = 18, children, ...rest }: IconProps & { children: ReactNode }) {
  return (
    <svg
      viewBox="0 0 24 24"
      width={size}
      height={size}
      fill="none"
      stroke="currentColor"
      strokeWidth={1.6}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
      {...rest}
    >
      {children}
    </svg>
  );
}

/**
 * Dron de entrega visto desde arriba, apuntando al norte: fuselaje, ala recta
 * con dos góndolas de rotor (despega en vertical) y cola en V.
 */
export const DroneIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d={DRONE_BODY} />
    {DRONE_WINGS.map((wing) => (
      <path key={wing} d={wing} />
    ))}
    {DRONE_ROTORS.map(([cx, cy]) => (
      <circle key={cx} cx={cx} cy={cy} r={DRONE_ROTOR_R} />
    ))}
  </Icon>
);

/** Central genérica: edificio con cruz médica. */
export const HubIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M4.5 20.5V9.2L12 4.5l7.5 4.7v11.3" />
    <path d="M3 20.5h18" />
    <path d="M12 10.2v5.2M9.4 12.8h5.2" />
  </Icon>
);

const ClinicIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="5" y="3.5" width="14" height="17" rx="1.6" />
    <path d="M3 20.5h18M12 7v4.4M9.8 9.2h4.4M10 20.5v-4h4v4" />
  </Icon>
);

const PharmacyIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="3.2" y="8.8" width="17.6" height="6.4" rx="3.2" transform="rotate(-45 12 12)" />
    <path d="M9.7 9.7l4.6 4.6" />
  </Icon>
);

const BloodBankIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M12 3.2c-3 4-6.2 7.3-6.2 10.6a6.2 6.2 0 0 0 12.4 0c0-3.3-3.2-6.6-6.2-10.6z" />
    <path d="M12 11.6v4.6M9.7 13.9h4.6" />
  </Icon>
);

const VaccinationIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M16.5 3.5l4 4M18.5 5.5l-3 3" />
    <path d="M13.2 6.8l4 4-7.6 7.6-4-4z" />
    <path d="M5.6 18.4 3.5 20.5M9.6 10.4l1.4 1.4M7.6 12.4l1.4 1.4" />
  </Icon>
);

/** El ícono de cada tipo de central (`HUB_TYPE`). */
export function HubTypeIcon({ type, ...p }: IconProps & { type: string }) {
  switch (type) {
    case "clinic":
      return <ClinicIcon {...p} />;
    case "pharmacy":
      return <PharmacyIcon {...p} />;
    case "blood_bank":
      return <BloodBankIcon {...p} />;
    case "vaccination":
      return <VaccinationIcon {...p} />;
    default:
      return <HubIcon {...p} />;
  }
}

export const CloseIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M6.5 6.5l11 11M17.5 6.5l-11 11" />
  </Icon>
);

export const ChevronIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M9.5 6.5 15 12l-5.5 5.5" />
  </Icon>
);

export const BatteryIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="2.8" y="7.5" width="16" height="9" rx="2" />
    <path d="M21.2 10.8v2.4" />
  </Icon>
);

/** Velocímetro. */
export const SpeedIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M4 17.5a8.5 8.5 0 1 1 16 0" />
    <path d="M12 14.5l3.6-4.2" />
    <circle cx="12" cy="14.5" r="0.9" fill="currentColor" stroke="none" />
  </Icon>
);

/** Altitud: una cota sobre el terreno. */
export const AltitudeIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M3 20.5h18" />
    <path d="M3.5 20.5 9 13l3.5 4 2.5-3 5.5 6.5" />
    <path d="M16.5 9.5V3.5M14.3 5.7l2.2-2.2 2.2 2.2" />
  </Icon>
);

export const ThermometerIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M10.2 4.6a1.8 1.8 0 0 1 3.6 0v9.6a3.8 3.8 0 1 1-3.6 0z" />
    <path d="M12 17.2V10" />
  </Icon>
);

export const ClockIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="12" cy="12" r="8.5" />
    <path d="M12 7.5V12l3 1.8" />
  </Icon>
);

/** Fase del vuelo: la curva de ascenso. */
export const PhaseIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M3 20.5h18" />
    <path d="M4 17c2.5-.4 4.2-2.8 6-6.2S14.5 4.6 20 4.5" />
    <circle cx="4" cy="17" r="1.3" />
  </Icon>
);

export const SnowflakeIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M12 3v18M4.2 7.5l15.6 9M19.8 7.5l-15.6 9" />
    <path d="M9.8 4.6 12 6.8l2.2-2.2M9.8 19.4l2.2-2.2 2.2 2.2" />
  </Icon>
);

/** Espera rescate y toda alerta. */
export const AlertIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M10.3 4.2L2.6 17.5A2 2 0 0 0 4.3 20.5h15.4a2 2 0 0 0 1.7-3L13.7 4.2a2 2 0 0 0-3.4 0z" />
    <path d="M12 9.5v4M12 17h.01" />
  </Icon>
);

/** Zona restringida (geovalla): un polígono rayado, como en la carta. */
export const ShieldIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M4 7.5 9 4l9.5 2.5L20 15l-6.5 5L4.5 17z" />
    <path d="M7 13.5l5.5-5.5M9.5 16.5l6.5-6.5" />
  </Icon>
);

export const LogoutIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M14 4.5h3.5a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H14" />
    <path d="M9.5 16 5.5 12l4-4M5.5 12h10" />
  </Icon>
);

export const PhoneIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M5.2 4h3.2l1.8 4.6-2.3 1.4a10.5 10.5 0 0 0 6.1 6.1l1.4-2.3 4.6 1.8v3.2a1.8 1.8 0 0 1-1.8 1.8A15.8 15.8 0 0 1 3.4 5.8 1.8 1.8 0 0 1 5.2 4z" />
  </Icon>
);

export const MailIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="3" y="5.5" width="18" height="13" rx="2" />
    <path d="m3.8 7.2 8.2 5.6 8.2-5.6" />
  </Icon>
);

/** Paquete: la caja de la carga. */
export const PackageIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M3.5 7.5 12 3.5l8.5 4v9L12 20.5l-8.5-4z" />
    <path d="M3.5 7.5 12 11.5l8.5-4M12 11.5v9M7.8 5.5l8.4 4" />
  </Icon>
);

/** Ruta: dos puntos unidos por un camino. */
export const RouteIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="5.5" cy="18.5" r="2" />
    <circle cx="18.5" cy="5.5" r="2" />
    <path d="M7.5 18.5H16a3.2 3.2 0 0 0 0-6.4H8a3.2 3.2 0 0 1 0-6.4h8.5" />
  </Icon>
);

/** Línea de tiempo: renglones con su hora. */
export const ListIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M9 6.5h11M9 12h11M9 17.5h7" />
    <circle cx="4.5" cy="6.5" r="1" fill="currentColor" stroke="none" />
    <circle cx="4.5" cy="12" r="1" fill="currentColor" stroke="none" />
    <circle cx="4.5" cy="17.5" r="1" fill="currentColor" stroke="none" />
  </Icon>
);

export const CheckIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M5 12.5 9.8 17 19 7.5" />
  </Icon>
);

export const PauseIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="6.5" y="5" width="3.5" height="14" rx="1" />
    <rect x="14" y="5" width="3.5" height="14" rx="1" />
  </Icon>
);

export const PlayIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M7.5 5.6v12.8a.9.9 0 0 0 1.4.8l10-6.4a.9.9 0 0 0 0-1.6l-10-6.4a.9.9 0 0 0-1.4.8z" />
  </Icon>
);

/** Flecha que vuelve: reiniciar el escenario. */
export const ResetIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M4 12a8 8 0 1 0 2.4-5.7" />
    <path d="M4 4v4.5h4.5" />
  </Icon>
);

/* Consola: clima, zonas, energía y el catálogo de incidentes (RF-32 a RF-36). */

export const WindIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M3 8.5h11a2.5 2.5 0 1 0-2.5-2.5" />
    <path d="M3 12.5h15a2.5 2.5 0 1 1-2.5 2.5" />
    <path d="M3 16.5h7" />
  </Icon>
);

export const RainIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M7 15.5a4.5 4.5 0 0 1-.6-9 5.5 5.5 0 0 1 10.6 1.2A3.9 3.9 0 0 1 17 15.5z" />
    <path d="M8.5 18.5l-1 2M12.5 18.5l-1 2M16.5 18.5l-1 2" />
  </Icon>
);

/** Tormenta: la nube de la lluvia con un rayo. */
export const StormIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M7 15a4.5 4.5 0 0 1-.6-9 5.5 5.5 0 0 1 10.6 1.2A3.9 3.9 0 0 1 17 15h-.5" />
    <path d="M12.8 11.5 10.5 15.5h3.2L11.5 20" />
  </Icon>
);

/** Zona temporal: un área de trazos con un reloj. */
export const ZoneIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="3.5" y="3.5" width="17" height="17" rx="2.5" strokeDasharray="2.6 2.4" />
    <circle cx="12" cy="12" r="4" />
    <path d="M12 10v2l1.3.9" />
  </Icon>
);

/** Rayo tachado: sin energía. */
export const PowerOffIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M13 3L6.5 13H12l-1 8 6.5-10H12z" />
    <path d="M3.5 3.5l17 17" />
  </Icon>
);

/** Rayo: con energía. */
export const PowerIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M13 3 6.5 13H12l-1 8 6.5-10H12z" />
  </Icon>
);

export const PlusIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M12 5.5v13M5.5 12h13" />
  </Icon>
);

export const MinusIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M5.5 12h13" />
  </Icon>
);

/** Recentrar: las cuatro esquinas de un encuadre. */
export const RecenterIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M4 8.5V5.5A1.5 1.5 0 0 1 5.5 4h3M15.5 4h3A1.5 1.5 0 0 1 20 5.5v3M20 15.5v3a1.5 1.5 0 0 1-1.5 1.5h-3M8.5 20h-3A1.5 1.5 0 0 1 4 18.5v-3" />
    <circle cx="12" cy="12" r="2.2" />
  </Icon>
);

export const ArrowRightIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M5 12h14M13.5 6.5 19 12l-5.5 5.5" />
  </Icon>
);

export const LockIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="5" y="10.5" width="14" height="10" rx="2" />
    <path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5" />
  </Icon>
);

export const EyeIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M2.8 12S6.2 6 12 6s9.2 6 9.2 6-3.4 6-9.2 6-9.2-6-9.2-6z" />
    <circle cx="12" cy="12" r="2.8" />
  </Icon>
);

export const PinIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M12 20.5s-6-5.2-6-10.3a6 6 0 0 1 12 0c0 5.1-6 10.3-6 10.3z" />
    <circle cx="12" cy="10.2" r="2.1" />
  </Icon>
);

/** Batería con una sola raya: degradada. */
export const BatteryLowIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="2.8" y="7.5" width="16" height="9" rx="2" />
    <path d="M21.2 10.8v2.4M6.3 10.5v3" />
  </Icon>
);

/** Rotor: un motor del dron, con dos palas. */
export const MotorIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="12" cy="12" r="8.5" strokeDasharray="2 2.6" />
    <circle cx="12" cy="12" r="1.6" />
    <path d="M10.6 11.2C8 9.8 6.5 7.6 7.2 6.4s3.4-.3 4.6 3.9M13.4 12.8c2.6 1.4 4.1 3.6 3.4 4.8s-3.4.3-4.6-3.9" />
  </Icon>
);

/** Posición: una mira con su punto. */
export const GpsIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="12" cy="12" r="6.5" />
    <circle cx="12" cy="12" r="1.6" fill="currentColor" stroke="none" />
    <path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3" />
  </Icon>
);

/** Señal tachada: sin enlace. */
export const LinkOffIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M5 12.5a9.5 9.5 0 0 1 14 0M8 15.5a5.2 5.2 0 0 1 8 0" />
    <circle cx="12" cy="19" r="1.1" fill="currentColor" stroke="none" />
    <path d="M4 4l16 16" />
  </Icon>
);

/** Choque: un impacto con sus esquirlas. */
export const CollisionIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="m12 6.5 1.6 3.4 3.6-.9-1.6 3.3 3 2.2-3.7.6.3 3.7L12 16.6 8.8 18.8l.3-3.7-3.7-.6 3-2.2-1.6-3.3 3.6.9z" />
    <path d="M12 2.5v1.5M4.5 5l1 1M19.5 5l-1 1" />
  </Icon>
);

/** Dron perdido: el círculo de búsqueda con un signo de pregunta. */
export const LostIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="12" cy="12" r="8.5" strokeDasharray="2.6 2.6" />
    <path d="M9.8 9.6a2.3 2.3 0 1 1 3.2 2.1c-.6.3-1 .8-1 1.5v.5" />
    <circle cx="12" cy="16.6" r="0.9" fill="currentColor" stroke="none" />
  </Icon>
);

/** Actores simulados (RF-37): dos personas, una de ellas hecha de trazos. */
export const BotIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="9" cy="8" r="3.2" />
    <path d="M3 19.5c.5-3.3 2.9-5.3 6-5.3s5.5 2 6 5.3" />
    <circle cx="16.8" cy="9" r="2.6" strokeDasharray="2 1.6" />
    <path d="M17.5 14.4c2 .5 3.2 2.1 3.5 4.6" strokeDasharray="2 1.6" />
  </Icon>
);

/** Pico de urgencias (RF-36): tres puntos de pedido juntos. */
export const SurgeIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M12 20.5s-4.2-3.6-4.2-7a4.2 4.2 0 0 1 8.4 0c0 3.4-4.2 7-4.2 7z" />
    <circle cx="12" cy="13.4" r="1.4" />
    <path d="M5.4 15.4C4 14 3 12.5 3 11a3.2 3.2 0 0 1 4.4-3M18.6 15.4C20 14 21 12.5 21 11a3.2 3.2 0 0 0-4.4-3" />
  </Icon>
);

/** Modo caos: un dado con sus puntos. */
export const ChaosIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="4" y="4" width="16" height="16" rx="3.2" />
    <circle cx="8.6" cy="8.6" r="1.1" fill="currentColor" stroke="none" />
    <circle cx="15.4" cy="8.6" r="1.1" fill="currentColor" stroke="none" />
    <circle cx="12" cy="12" r="1.1" fill="currentColor" stroke="none" />
    <circle cx="8.6" cy="15.4" r="1.1" fill="currentColor" stroke="none" />
    <circle cx="15.4" cy="15.4" r="1.1" fill="currentColor" stroke="none" />
  </Icon>
);

/** Leyenda del mapa: una carta plegada. */
export const LegendIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M3.5 6.5 9 4l6 2.5L20.5 4v13.5L15 20l-6-2.5L3.5 20z" />
    <path d="M9 4v13.5M15 6.5V20" />
  </Icon>
);
