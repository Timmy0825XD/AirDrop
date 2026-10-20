/** Solo los navegadores aplican CORS: las apps móviles no envían `Origin`. */
const LOCAL_ORIGIN = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

/**
 * `CORS_ORIGINS` lista los orígenes permitidos separados por comas. Sin ella,
 * en desarrollo se aceptan los de localhost y en producción ninguno.
 */
export function corsOrigins(
  configured: string | undefined,
  nodeEnv: string | undefined,
): string[] | RegExp | false {
  const origins = (configured ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  if (origins.length) {
    return origins;
  }
  return nodeEnv === 'production' ? false : LOCAL_ORIGIN;
}
