import { renderOtpEmail } from './otp-email';

describe('renderOtpEmail', () => {
  const content = {
    name: 'Ana <script>',
    code: '123456',
    minutes: 10,
    headline: 'Activa tu cuenta',
    intro: 'Usa este código.',
    ignore: 'Ignora este correo.',
  };

  it('renders the name and the code inside the branded layout', () => {
    const html = renderOtpEmail(content);
    expect(html).toContain('AirDrop');
    expect(html).toContain('123456');
    expect(html).toContain('10 minutos');
    expect(html).toContain('Ana &lt;script&gt;');
    expect(html).not.toContain('<script>');
  });
});
