import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

const BREVO_SEND_URL = 'https://api.brevo.com/v3/smtp/email';

export type OutboundEmail = {
  toEmail: string;
  toName: string;
  subject: string;
  html: string;
};

@Injectable()
export class BrevoMailService {
  private readonly logger = new Logger(BrevoMailService.name);

  constructor(private readonly config: ConfigService) {}

  isConfigured(): boolean {
    return this.apiKey().length > 0 && this.senderEmail().length > 0;
  }

  async send(message: OutboundEmail): Promise<void> {
    const apiKey = this.apiKey();
    const senderEmail = this.senderEmail();
    if (!apiKey || !senderEmail) {
      throw new ServiceUnavailableException(
        'El envío de correos no está configurado.',
      );
    }

    let response: Response;
    try {
      response = await fetch(BREVO_SEND_URL, {
        method: 'POST',
        headers: {
          accept: 'application/json',
          'content-type': 'application/json',
          'api-key': apiKey,
        },
        body: JSON.stringify({
          sender: { email: senderEmail, name: this.senderName() },
          to: [{ email: message.toEmail, name: message.toName }],
          subject: message.subject,
          htmlContent: message.html,
        }),
        signal: AbortSignal.timeout(10_000),
      });
    } catch (error) {
      this.logger.error(
        `Brevo no respondió: ${error instanceof Error ? error.name : 'error'}`,
      );
      throw new ServiceUnavailableException(
        'No pudimos enviar el correo. Intenta de nuevo en unos minutos.',
      );
    }

    if (!response.ok) {
      const detail = await this.readError(response);
      this.logger.error(
        `Brevo rechazó el correo (${response.status}). ${detail}`,
      );
      throw new ServiceUnavailableException(
        'No pudimos enviar el correo. Intenta de nuevo en unos minutos.',
      );
    }

    this.logger.log('Brevo aceptó el correo transaccional.');
  }

  private apiKey(): string {
    return this.config.get<string>('BREVO_API_KEY', '').trim();
  }

  private senderEmail(): string {
    return this.config.get<string>('BREVO_SENDER_EMAIL', '').trim();
  }

  private senderName(): string {
    return this.config.get<string>('BREVO_SENDER_NAME', 'AirDrop').trim();
  }

  private async readError(response: Response): Promise<string> {
    try {
      const body = (await response.json()) as { message?: unknown };
      if (typeof body.message === 'string') {
        return body.message.slice(0, 200);
      }
    } catch {
      return 'sin detalle';
    }
    return 'sin detalle';
  }
}
