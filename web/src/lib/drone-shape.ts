/**
 * La silueta del dron de entrega, vista desde arriba y apuntando al norte,
 * en una cuadrícula de 24. La usan el ícono, la marca y el mapa (que la pinta
 * en un lienzo con `Path2D`), así el dron es el mismo en toda la consola.
 */

/** Fuselaje con la cola en V. */
export const DRONE_BODY =
  "M12 2.8c.9 0 1.5.9 1.5 2.2V16l2.3 1.9v1.4L12 18.4l-3.8.9v-1.4l2.3-1.9V5c0-1.3.6-2.2 1.5-2.2z";

/** Las dos alas rectas. */
export const DRONE_WINGS = [
  "M10.5 9.2 2.8 11.4v1.5l7.7-.9z",
  "M13.5 9.2l7.7 2.2v1.5l-7.7-.9z",
];

/** Góndolas de rotor sobre el ala: despega y aterriza en vertical. */
export const DRONE_ROTORS: Array<[number, number]> = [
  [6.2, 11.3],
  [17.8, 11.3],
];
export const DRONE_ROTOR_R = 1.7;
