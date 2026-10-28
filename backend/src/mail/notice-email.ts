/** Correo de un aviso de la bandeja: el mismo texto, con un saludo. */
export function renderNoticeEmail(content: {
  name: string;
  title: string;
  body: string;
}): string {
  const name = escapeHtml(content.name);
  const title = escapeHtml(content.title);
  const body = escapeHtml(content.body);
  return `<!doctype html>
<html lang="es">
<head><meta charset="utf-8"><title>${title}</title></head>
<body style="margin:0;padding:24px;background:#F4F7F6;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#1B2A33;">
  <p style="margin:0 0 12px;font-size:16px;">Hola, ${name}:</p>
  <p style="margin:0 0 8px;font-size:17px;font-weight:600;">${title}</p>
  <p style="margin:0 0 12px;font-size:15px;">${body}</p>
  <p style="margin:0 0 12px;font-size:14px;color:#52616B;">Lo ves también en la bandeja de avisos de la app.</p>
  <p style="margin:16px 0 0;font-size:12px;color:#8B98A5;">AirDrop · Valledupar</p>
</body>
</html>`;
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}
