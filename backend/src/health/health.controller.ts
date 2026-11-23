import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { DataSource } from 'typeorm';

/**
 * Lo consulta Azure App Service para dar por bueno un arranque. Es público y
 * no expone datos.
 */
@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly dataSource: DataSource) {}

  @Get()
  async check(): Promise<{ status: 'ok' }> {
    try {
      await this.dataSource.query('SELECT 1');
    } catch {
      throw new ServiceUnavailableException('La base de datos no responde.');
    }
    return { status: 'ok' };
  }
}
