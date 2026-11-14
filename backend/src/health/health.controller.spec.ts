import { ServiceUnavailableException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { HealthController } from './health.controller';

function controllerWith(query: jest.Mock): HealthController {
  return new HealthController({ query } as unknown as DataSource);
}

describe('HealthController', () => {
  it('responde ok cuando la base de datos contesta', async () => {
    const query = jest.fn().mockResolvedValue([{ '?column?': 1 }]);

    await expect(controllerWith(query).check()).resolves.toEqual({
      status: 'ok',
    });
    expect(query).toHaveBeenCalledWith('SELECT 1');
  });

  it('responde 503 cuando la base de datos no contesta', async () => {
    const query = jest.fn().mockRejectedValue(new Error('timeout'));

    await expect(controllerWith(query).check()).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });
});
