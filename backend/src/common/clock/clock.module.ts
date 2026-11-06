import { Module } from '@nestjs/common';
import { SimTimeSubscriber } from './sim-time.subscriber';

/** Registra la hora simulada en las fechas de creación (RF-31). */
@Module({
  providers: [SimTimeSubscriber],
})
export class ClockModule {}
