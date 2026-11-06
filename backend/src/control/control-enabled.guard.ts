import { CanActivate, Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CONTROL_DISABLED, isControlEnabled } from './control.rules';

/** RF-40: con la consola apagada, `/control/*` no existe (404). */
@Injectable()
export class ControlEnabledGuard implements CanActivate {
  constructor(private readonly config: ConfigService) {}

  canActivate(): boolean {
    if (!isControlEnabled(this.config.get<string>('CONTROL_ENABLED'))) {
      throw new NotFoundException(CONTROL_DISABLED);
    }
    return true;
  }
}
