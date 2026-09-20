import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';
import { OneTimeCode } from '../auth/one-time-code.entity';
import { Drone } from '../fleet/drone.entity';
import { DroneModel } from '../fleet/drone-model.entity';
import { Hub } from '../hubs/hub.entity';
import { InventoryItem } from '../inventory/inventory-item.entity';
import { Geofence } from '../geofences/geofence.entity';
import { User } from '../users/user.entity';

export function typeOrmOptions(config: ConfigService): TypeOrmModuleOptions {
  const url = config.get<string>('DATABASE_URL');
  if (!url) {
    throw new Error(
      'Falta DATABASE_URL. Copia backend/.env.example a backend/.env y pega la URI de Supabase (Session pooler, puerto 5432).',
    );
  }

  const isTest = config.get<string>('NODE_ENV') === 'test';

  return {
    type: 'postgres',
    url,
    ssl: { rejectUnauthorized: false },
    entities: [User, OneTimeCode, Hub, DroneModel, Drone, InventoryItem, Geofence],
    synchronize: config.get<string>('NODE_ENV') !== 'production',
    dropSchema: isTest && config.get<string>('E2E_DROP_SCHEMA') === 'true',
    retryAttempts: isTest ? 1 : 10,
    logging: false,
  };
}
