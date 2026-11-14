import type { MetadataRoute } from "next";

// Los íconos salen del paquete de marca (_brand/logo/favicon). El color de
// fondo es el de la consola, no el de la app.
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "AirDrop Radar",
    short_name: "AirDrop",
    description: "Centrales, drones y entregas en tiempo real.",
    start_url: "/",
    display: "standalone",
    background_color: "#090c10",
    theme_color: "#090c10",
    icons: [
      { src: "/icon-192.png", sizes: "192x192", type: "image/png" },
      { src: "/icon-512.png", sizes: "512x512", type: "image/png" },
      { src: "/icon-maskable-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
  };
}
