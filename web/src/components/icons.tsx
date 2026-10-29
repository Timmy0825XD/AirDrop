import type { ReactNode, SVGProps } from "react";

/** Íconos de trazo (24 × 24) en `currentColor`. Un solo lugar para todos. */

type IconProps = SVGProps<SVGSVGElement> & { size?: number };

function Icon({ size = 18, children, ...rest }: IconProps & { children: ReactNode }) {
  return (
    <svg
      viewBox="0 0 24 24"
      width={size}
      height={size}
      fill="none"
      stroke="currentColor"
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
      {...rest}
    >
      {children}
    </svg>
  );
}

/** Dron de frente: hélices, brazos, cuerpo y patas de aterrizaje. */
export const DroneIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M1.5 7.5h6M16.5 7.5h6" />
    <path d="M4.5 7.5v4h3M19.5 7.5v4h-3" />
    <path d="M9 10h6a1.8 1.8 0 0 1 1.8 1.8v.7a3.5 3.5 0 0 1-3.5 3.5h-2.6a3.5 3.5 0 0 1-3.5-3.5v-.7A1.8 1.8 0 0 1 9 10z" />
    <path d="M9.5 16l-1.8 3.5M14.5 16l1.8 3.5M6.5 19.5h2.5M15 19.5h2.5" />
    <circle cx="12" cy="13" r="1" fill="currentColor" stroke="none" />
  </Icon>
);

/** Central genérica: edificio con cruz médica. */
export const HubIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M4 20.5V9l8-5.5L20 9v11.5" />
    <path d="M2.5 20.5h19" />
    <path d="M12 10v6M9 13h6" />
  </Icon>
);

const ClinicIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M5 20.5V5a1.5 1.5 0 0 1 1.5-1.5h11A1.5 1.5 0 0 1 19 5v15.5" />
    <path d="M3 20.5h18" />
    <path d="M12 6.5v5M9.5 9h5" />
    <path d="M10 20.5v-4h4v4" />
  </Icon>
);

const PharmacyIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="3" y="8.5" width="18" height="7" rx="3.5" transform="rotate(-45 12 12)" />
    <path d="M9.5 9.5l5 5" />
  </Icon>
);

const BloodBankIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M12 3c-3.2 4.2-6.5 7.6-6.5 11a6.5 6.5 0 0 0 13 0c0-3.4-3.3-6.8-6.5-11z" />
    <path d="M12 11.5v5M9.5 14h5" />
  </Icon>
);

const VaccinationIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M17 3l4 4M19 5l-3.5 3.5" />
    <path d="M13 6.5l4.5 4.5-8 8-4.5-4.5z" />
    <path d="M5 19l-2.5 2.5" />
    <path d="M10 9.5l1.5 1.5M7.8 11.8l1.5 1.5" />
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
    <path d="M6 6l12 12M18 6L6 18" />
  </Icon>
);

export const ChevronIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M9 6l6 6-6 6" />
  </Icon>
);

export const BatteryIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="2.5" y="7" width="17" height="10" rx="2.5" />
    <path d="M22 10.5v3" />
  </Icon>
);

export const SpeedIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M3.5 17.5a9 9 0 1 1 17 0" />
    <path d="M12 14l4-4.5" />
  </Icon>
);

export const AltitudeIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M2.5 20.5l6-8.5 4 5 3-3.5 6 7z" />
    <path d="M17 9V3M14.5 5.5L17 3l2.5 2.5" />
  </Icon>
);

export const ThermometerIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M10 4.5a2 2 0 1 1 4 0v9.8a4 4 0 1 1-4 0z" />
    <path d="M12 17.5V10" />
  </Icon>
);

export const ClockIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="12" cy="12" r="9" />
    <path d="M12 7v5l3.2 2" />
  </Icon>
);

export const PhaseIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M3 17c3-1 5-4 7-8s4-5.5 11-6" />
    <circle cx="3" cy="17" r="1.5" />
    <path d="M3 21h18" />
  </Icon>
);

export const SnowflakeIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M12 2.5v19M3.8 7.25l16.4 9.5M20.2 7.25l-16.4 9.5" />
    <path d="M9.5 4L12 6.5 14.5 4M9.5 20l2.5-2.5 2.5 2.5" />
  </Icon>
);

export const AlertIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M10.3 4.2L2.6 17.5A2 2 0 0 0 4.3 20.5h15.4a2 2 0 0 0 1.7-3L13.7 4.2a2 2 0 0 0-3.4 0z" />
    <path d="M12 9.5v4M12 17h.01" />
  </Icon>
);

/** Zona restringida (geovalla). */
export const ShieldIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M12 3l7.5 3v5.5c0 4.6-3.2 8.4-7.5 9.5-4.3-1.1-7.5-4.9-7.5-9.5V6z" />
    <path d="M9.5 9.5l5 5M14.5 9.5l-5 5" />
  </Icon>
);

export const LogoutIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M14.5 4H18a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3.5" />
    <path d="M9.5 16.5L5 12l4.5-4.5M5 12h11" />
  </Icon>
);

export const PhoneIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M5 3.5h3.5l2 5-2.5 1.5a11 11 0 0 0 6 6l1.5-2.5 5 2V19a2 2 0 0 1-2 2A16.5 16.5 0 0 1 3 5.5a2 2 0 0 1 2-2z" />
  </Icon>
);

export const MailIcon = (p: IconProps) => (
  <Icon {...p}>
    <rect x="3" y="5" width="18" height="14" rx="2.5" />
    <path d="M3.5 7l8.5 6 8.5-6" />
  </Icon>
);

export const PackageIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M3 7.5L12 3l9 4.5v9L12 21l-9-4.5z" />
    <path d="M3 7.5l9 4.5 9-4.5M12 12v9M7.5 5.2l9 4.6" />
  </Icon>
);

export const RouteIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="6" cy="19" r="2" />
    <circle cx="18" cy="5" r="2" />
    <path d="M8 19h8.5a3.5 3.5 0 0 0 0-7h-9a3.5 3.5 0 0 1 0-7H16" />
  </Icon>
);

export const ListIcon = (p: IconProps) => (
  <Icon {...p}>
    <path d="M8.5 6H21M8.5 12H21M8.5 18H21M3.5 6h.01M3.5 12h.01M3.5 18h.01" />
  </Icon>
);

export const CheckIcon = (p: IconProps) => (
  <Icon {...p}>
    <circle cx="12" cy="12" r="9" />
    <path d="M8 12.5l2.7 2.7L16 9.8" />
  </Icon>
);
