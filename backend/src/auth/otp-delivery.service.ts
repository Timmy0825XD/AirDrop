import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OtpPurpose } from '../common/enums/otp-purpose.enum';

@Injectable()
export class OtpDeliveryService {
  private readonly logger = new Logger(OtpDeliveryService.name);

  constructor(private readonly config: ConfigService) {}

  deliver(purpose: OtpPurpose, code: string): void {
    const env = this.config.get<string>('NODE_ENV', 'development');
    if (env === 'production') {
      throw new ServiceUnavailableException(
        'El envío de códigos no está configurado en este ambiente.',
      );
    }
    this.logger.log(`OTP ${purpose} (solo desarrollo/pruebas): ${code}`);
  }
}
