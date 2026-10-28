/**
 * Aviso al correo anterior cuando se confirma un cambio de correo. El correo
 * nuevo va enmascarado: el aviso puede leerlo alguien que ya no es dueño de
 * la cuenta.
 */
export function renderEmailChangedNotice(content: {
  name: string;
  newEmail: string;
}): string {
  const name = escapeHtml(content.name);
  const masked = escapeHtml(maskEmail(content.newEmail));
  return `<!doctype html>
<html lang="es">
<body style="margin:0;padding:24px;background:#F4F7F6;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#1B2A33;">
  <p style="margin:0 0 12px;font-size:16px;">Hola, ${name}:</p>
  <p style="margin:0 0 12px;font-size:15px;">El correo de tu cuenta de AirDrop cambió a <strong>${masked}</strong>. Desde ahora inicias sesión y recuperas tu contraseña con ese correo.</p>
  <p style="margin:0 0 12px;font-size:15px;">Si no hiciste este cambio, comunícate con tu central o con el administrador de AirDrop.</p>
  <p style="margin:16px 0 0;font-size:12px;color:#8B98A5;">AirDrop · Valledupar</p>
</body>
</html>`;
}

/** `daniela@gmail.com` → `d*****a@gmail.com`. */
export function maskEmail(email: string): string {
  const [local, domain] = email.split('@');
  if (!domain) {
    return '***';
  }
  if (local.length <= 2) {
    return `${local[0] ?? ''}***@${domain}`;
  }
  return `${local[0]}${'*'.repeat(local.length - 2)}${local.at(-1)}@${domain}`;
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}
