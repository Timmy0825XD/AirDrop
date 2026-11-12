/// Mensaje cuando un build de release no trae una dirección HTTPS.
const String releaseNeedsHttps =
    'El build de release necesita --dart-define=API_BASE_URL=https://... '
    '(no se permite HTTP sin cifrar).';

/// Dirección del backend (H-01 y H-02).
///
/// [configured] llega de `--dart-define=API_BASE_URL`. En desarrollo, si no
/// se pasa, se usa el backend local: en el emulador de Android `localhost`
/// es el propio emulador y `10.0.2.2` es el PC. En release la dirección es
/// obligatoria y tiene que ser `https://`: la app no manda la contraseña,
/// el token ni la fórmula sin cifrar. El socket de telemetría arma su
/// dirección con esta misma base, así que con `https://` usa `wss://`.
String resolveApiBaseUrl({
  required String configured,
  required bool release,
  required bool web,
  required bool android,
}) {
  final url = configured.trim();
  if (url.isNotEmpty) {
    if (release && !url.startsWith('https://')) {
      throw StateError(releaseNeedsHttps);
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
  if (release) throw StateError(releaseNeedsHttps);
  if (!web && android) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}
