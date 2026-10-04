import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OtpPurpose } from '../common/enums/otp-purpose.enum';
import { BrevoMailService, OutboundEmail } from '../mail/brevo-mail.service';
import { OtpDeliveryService } from './otp-delivery.service';

describe('OtpDeliveryService', () => {
  function build(env: string, configured: boolean) {
    const config = {
      get: (_key: string, fallback?: string) =>
        _key === 'NODE_ENV' ? env : (fallback ?? ''),
    } as ConfigService;
    const sent: OutboundEmail[] = [];
    const send = jest.fn((message: OutboundEmail) => {
      sent.push(message);
      return Promise.resolve();
    });
    const mail = {
      isConfigured: () => configured,
      send,
    } as unknown as BrevoMailService;
    return {
      delivery: new OtpDeliveryService(config, mail),
      send,
      sent,
    };
  }

  const email = {
    channel: 'email' as const,
    email: 'ana.perez@gmail.com',
    name: 'Ana Pérez',
  };

  it('does not call Brevo during tests', async () => {
    const { delivery, send } = build('test', true);
    await delivery.deliver(OtpPurpose.PASSWORD_RESET, '123456', email);
    expect(send).not.toHaveBeenCalled();
  });

  it('sends the reset code by email when Brevo is configured', async () => {
    const { delivery, send, sent } = build('development', true);
    await delivery.deliver(OtpPurpose.PASSWORD_RESET, '123456', email);
    expect(send).toHaveBeenCalledTimes(1);
    expect(sent[0]).toMatchObject({
      toEmail: email.email,
      toName: email.name,
      subject: 'Código para restablecer tu contraseña',
    });
    expect(sent[0]?.html).toContain('123456');
    expect(sent[0]?.html).toContain('Ana Pérez');
    expect(sent[0]?.html).toContain('Restablece tu contraseña');
  });

  it('sends the signup code by email when the account has one', async () => {
    const { delivery, sent } = build('development', true);
    await delivery.deliver(OtpPurpose.SIGNUP, '654321', email);
    expect(sent[0]).toMatchObject({
      toEmail: email.email,
      subject: 'Código para activar tu cuenta',
    });
    expect(sent[0]?.html).toContain('10 minutos');
    expect(sent[0]?.html).toContain('654321');
    expect(sent[0]?.html).toContain('Activa tu cuenta');
  });

  it('refuses email delivery in production when Brevo is missing', async () => {
    const { delivery } = build('production', false);
    await expect(
      delivery.deliver(OtpPurpose.PASSWORD_RESET, '123456', email),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });
});
