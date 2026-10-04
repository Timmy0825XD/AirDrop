export type OtpEmailContent = {
  name: string;
  code: string;
  minutes: number;
  headline: string;
  intro: string;
  ignore: string;
};

export function renderOtpEmail(content: OtpEmailContent): string {
  const name = escapeHtml(content.name);
  const code = escapeHtml(content.code);
  const headline = escapeHtml(content.headline);
  const intro = escapeHtml(content.intro);
  const ignore = escapeHtml(content.ignore);

  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${headline}</title>
</head>
<body style="margin:0;padding:0;background:#F5F7FA;">
  <div style="display:none;max-height:0;overflow:hidden;">${headline}. Tu código es ${code} y vence en ${content.minutes} minutos.</div>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#F5F7FA;padding:32px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#FFFFFF;border-radius:18px;overflow:hidden;">
          <tr>
            <td style="height:6px;background:#06B6D4;font-size:0;line-height:0;">&nbsp;</td>
          </tr>
          <tr>
            <td style="padding:28px 32px 8px;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
              <p style="margin:0;font-size:22px;font-weight:700;letter-spacing:-0.3px;color:#06B6D4;">AirDrop</p>
              <p style="margin:4px 0 0;font-size:13px;color:#5B6672;">Logística aérea de medicamentos</p>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 32px 0;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
              <p style="margin:0;font-size:20px;font-weight:700;color:#10151B;">${headline}</p>
              <p style="margin:12px 0 0;font-size:15px;line-height:1.5;color:#10151B;">Hola ${name},</p>
              <p style="margin:8px 0 0;font-size:15px;line-height:1.5;color:#5B6672;">${intro}</p>
            </td>
          </tr>
          <tr>
            <td style="padding:24px 32px 8px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#ECFEFF;border:1px solid #A5F3FC;border-radius:14px;">
                <tr>
                  <td align="center" style="padding:22px 16px;font-family:Consolas,Courier New,monospace;font-size:32px;font-weight:700;letter-spacing:8px;color:#0E7490;">${code}</td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:8px 32px 28px;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
              <p style="margin:0;font-size:14px;line-height:1.5;color:#10151B;">Vence en ${content.minutes} minutos y solo sirve una vez.</p>
              <p style="margin:16px 0 0;font-size:13px;line-height:1.5;color:#5B6672;">${ignore}</p>
            </td>
          </tr>
        </table>
        <p style="margin:16px 0 0;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:12px;color:#8B98A5;">AirDrop · Valledupar</p>
      </td>
    </tr>
  </table>
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
