import { Injectable } from '@nestjs/common';
import { DataSource, EntitySubscriberInterface, InsertEvent } from 'typeorm';
import { OneTimeCode } from '../../auth/one-time-code.entity';
import { User } from '../../users/user.entity';
import { simClock } from './sim-clock';

/** Cuentas y códigos son seguridad: su fecha de creación es la real. */
const REAL_TIME_ENTITIES: ReadonlySet<unknown> = new Set([User, OneTimeCode]);

/**
 * RF-31: la fecha de creación de un pedido, un aviso o una cuarentena es la
 * hora simulada. Sin esto Postgres pondría la real, y una regla como "la
 * urgencia lleva más de 5 minutos" compararía dos relojes distintos.
 */
@Injectable()
export class SimTimeSubscriber implements EntitySubscriberInterface {
  constructor(dataSource: DataSource) {
    dataSource.subscribers.push(this);
  }

  beforeInsert(event: InsertEvent<object>): void {
    const column = event.metadata.createDateColumn;
    if (!column || REAL_TIME_ENTITIES.has(event.metadata.target)) {
      return;
    }
    if (column.getEntityValue(event.entity) == null) {
      column.setEntityValue(event.entity, simClock.now());
    }
  }
}
