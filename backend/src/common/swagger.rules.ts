/**
 * H-07: la documentación de Swagger (`/api`) lista todos los endpoints, sus
 * parámetros y modelos. Sirve para desarrollar; en producción no se publica.
 */
export function swaggerEnabled(nodeEnv: string | undefined): boolean {
  return nodeEnv !== 'production';
}
