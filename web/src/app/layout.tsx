import type { Metadata, Viewport } from "next";
import { Space_Grotesk } from "next/font/google";
import "./globals.css";

// La misma tipografía de la app móvil.
const spaceGrotesk = Space_Grotesk({
  variable: "--font-space-grotesk",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "AirDrop Radar",
  description: "Centrales, drones y entregas en tiempo real.",
};

export const viewport: Viewport = {
  themeColor: "#14191d",
  colorScheme: "dark",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="es-CO" className={`${spaceGrotesk.variable} h-full antialiased`}>
      <body className="h-full">{children}</body>
    </html>
  );
}
