import type { Metadata, Viewport } from "next";
import { Figtree, IBM_Plex_Mono } from "next/font/google";
import "./globals.css";

// Las de la app: Figtree para todo y IBM Plex Mono para las cifras (hora, ID, métricas).
const figtree = Figtree({ variable: "--font-figtree", subsets: ["latin"] });
const plexMono = IBM_Plex_Mono({
  variable: "--font-plex-mono",
  subsets: ["latin"],
  weight: ["400", "500"],
});

/**
 * Antes de pintar, el tema guardado (o el oscuro): así no parpadea al cargar.
 * Lo mismo que `useTheme` hace después.
 */
const THEME_BOOT = `try{var t=localStorage.getItem("airdrop-theme");document.documentElement.dataset.theme=t==="light"?"light":"dark"}catch(e){document.documentElement.dataset.theme="dark"}`;

export const metadata: Metadata = {
  title: "AirDrop Radar",
  description: "Centrales, drones y entregas en tiempo real.",
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#f5f4f1" },
    { media: "(prefers-color-scheme: dark)", color: "#17191b" },
  ],
  colorScheme: "dark light",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="es-CO"
      data-theme="dark"
      suppressHydrationWarning
      className={`${figtree.variable} ${plexMono.variable} h-full antialiased`}
    >
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_BOOT }} />
      </head>
      <body className="h-full">{children}</body>
    </html>
  );
}
