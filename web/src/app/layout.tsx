import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

// Una sans de trabajo para todo y su mono para las cifras (hora, ID, métricas).
const geist = Geist({ variable: "--font-geist", subsets: ["latin"] });
const geistMono = Geist_Mono({ variable: "--font-geist-mono", subsets: ["latin"] });

export const metadata: Metadata = {
  title: "AirDrop Radar",
  description: "Centrales, drones y entregas en tiempo real.",
};

export const viewport: Viewport = {
  themeColor: "#090c10",
  colorScheme: "dark",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="es-CO" className={`${geist.variable} ${geistMono.variable} h-full antialiased`}>
      <body className="h-full">{children}</body>
    </html>
  );
}
