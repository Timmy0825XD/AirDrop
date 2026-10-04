import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OtpPurpose } from '../common/enums/otp-purpose.enum';
import { OTP_RESET_TTL_MS, OTP_SIGNUP_TTL_MS } from '../common/field-limits';
import { BrevoMailService } from '../mail/brevo-mail.service';
import { renderOtpEmail } from '../mail/otp-email';

export type OtpDestination = {
  channel: 'email';
  email: string;
  name: string;
};

@Injectable()
export class OtpDeliveryService {
  private readonly logger = new Logger(OtpDeliveryService.name);

  constructor(
    private readonly config: ConfigService,
    private readonly mail: BrevoMailService,
  ) {}

  async deliver(
    purpose: OtpPurpose,
    code: string,
    destination: OtpDestination,
  ): Promise<void> {
    const env = this.config.get<string>('NODE_ENV', 'development');
    if (env === 'test') {
      return;
    }
    if (!this.mail.isConfigured()) {
      if (env === 'production') {
        throw new ServiceUnavailableException(
          'El envío de correos no está configurado en este ambiente.',
        );
      }
      this.logger.log(`OTP ${purpose} (solo desarrollo/pruebas): ${code}`);
      return;
    }
    const copy = this.emailCopy(purpose);
    await this.mail.send({
      toEmail: destination.email,
      toName: destination.name,
      subject: copy.subject,
      html: renderOtpEmail({
        name: destination.name,
        code,
        minutes: copy.minutes,
        headline: copy.headline,
        intro: copy.intro,
        ignore: copy.ignore,
      }),
    });
  }

  private emailCopy(purpose: OtpPurpose): {
    minutes: number;
    subject: string;
    headline: string;
    intro: string;
    ignore: string;
  } {
    if (purpose === OtpPurpose.SIGNUP) {
      return {
        minutes: OTP_SIGNUP_TTL_MS / 60_000,
        subject: 'Código para activar tu cuenta',
        headline: 'Activa tu cuenta',
        intro:
          'Usa este código en la app para confirmar que este correo es tuyo.',
        ignore: 'Si no creaste una cuenta en AirDrop, ignora este correo.',
      };
    }
    return {
      minutes: OTP_RESET_TTL_MS / 60_000,
      subject: 'Código para restablecer tu contraseña',
      headline: 'Restablece tu contraseña',
      intro: 'Recibimos una solicitud para cambiar la contraseña de tu cuenta.',
      ignore: 'Si no pediste este cambio, ignora este correo.',
    };
  }
}
