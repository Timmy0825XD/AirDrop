import { Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import {
  InjectThrottlerOptions,
  InjectThrottlerStorage,
  ThrottlerGuard,
} from '@nestjs/throttler';

/**
 * ThrottlerGuard pide el Reflector de @nestjs/core por el constructor.
 * En Windows ese import a veces carga otra copia del paquete y Nest no
 * puede inyectarlo. Esta subclase le pasa un Reflector propio.
 */
@Injectable()
export class LoginRateLimitGuard extends ThrottlerGuard {
  constructor(
    @InjectThrottlerOptions()
    options: ConstructorParameters<typeof ThrottlerGuard>[0],
    @InjectThrottlerStorage()
    storage: ConstructorParameters<typeof ThrottlerGuard>[1],
  ) {
    super(options, storage, new Reflector());
  }
}
