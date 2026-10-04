import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { BrevoMailService } from './brevo-mail.service';

describe('BrevoMailService', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
  });

  function service(values: Record<string, string>): BrevoMailService {
    const config = {
      get: (key: string, fallback?: string) => values[key] ?? fallback ?? '',
    } as ConfigService;
    return new BrevoMailService(config);
  }

  const message = {
    toEmail: 'ana.perez@gmail.com',
    toName: 'Ana Pérez',
    subject: 'Código para restablecer tu contraseña',
    html: '<p>Tu código de AirDrop es 123456.</p>',
  };

  it('posts the transactional email to the Brevo API', async () => {
    const fetchMock = jest.fn().mockResolvedValue(
      new Response(JSON.stringify({ messageId: '<abc@smtp.brevo.com>' }), {
        status: 201,
      }),
    );
    global.fetch = fetchMock;
    const mail = service({
      BREVO_API_KEY: 'xkeysib-test',
      BREVO_SENDER_EMAIL: 'no-reply@airdrop.test',
      BREVO_SENDER_NAME: 'AirDrop',
    });

    await mail.send(message);

    expect(fetchMock).toHaveBeenCalledWith(
      'https://api.brevo.com/v3/smtp/email',
      expect.objectContaining({
        method: 'POST',
        headers: {
          accept: 'application/json',
          'content-type': 'application/json',
          'api-key': 'xkeysib-test',
        },
        body: JSON.stringify({
          sender: { email: 'no-reply@airdrop.test', name: 'AirDrop' },
          to: [{ email: message.toEmail, name: message.toName }],
          subject: message.subject,
          htmlContent: message.html,
        }),
      }),
    );
  });

  it('rejects a failed Brevo response without exposing the API key', async () => {
    global.fetch = jest.fn().mockResolvedValue(
      new Response(JSON.stringify({ message: 'sender is not valid' }), {
        status: 400,
      }),
    );
    const mail = service({
      BREVO_API_KEY: 'xkeysib-secret',
      BREVO_SENDER_EMAIL: 'no-reply@airdrop.test',
    });

    await expect(mail.send(message)).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it('is not configured without a key and a verified sender', () => {
    expect(service({}).isConfigured()).toBe(false);
    expect(
      service({
        BREVO_API_KEY: 'xkeysib-test',
        BREVO_SENDER_EMAIL: 'no-reply@airdrop.test',
      }).isConfigured(),
    ).toBe(true);
  });
});
