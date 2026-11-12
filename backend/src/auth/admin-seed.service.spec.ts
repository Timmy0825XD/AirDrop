import { ConfigService } from '@nestjs/config';
import { UserRole } from '../common/enums/user-role.enum';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import { AdminSeedService } from './admin-seed.service';
import { passwordsMatch } from './auth.rules';

describe('AdminSeedService', () => {
  function build(env: Record<string, string>, existing: User | null = null) {
    const config = {
      get: (key: string, fallback?: string) => env[key] ?? fallback,
    } as ConfigService;
    const save = jest.fn((user: User) => Promise.resolve(user));
    const users = {
      findByRole: jest.fn(() => Promise.resolve(existing)),
      create: (data: Partial<User>) => data as User,
      save,
    } as unknown as UsersService;
    return { seed: new AdminSeedService(users, config), save };
  }

  it('does not create the admin without ADMIN_PASSWORD (H-03)', async () => {
    const { seed, save } = build({});
    await seed.onModuleInit();
    expect(save).not.toHaveBeenCalled();
  });

  it('does not create the admin with a blank ADMIN_PASSWORD', async () => {
    const { seed, save } = build({ ADMIN_PASSWORD: '   ' });
    await seed.onModuleInit();
    expect(save).not.toHaveBeenCalled();
  });

  it('creates the admin with the configured password, hashed', async () => {
    const { seed, save } = build({ ADMIN_PASSWORD: 'Clave-Segura-2026' });
    await seed.onModuleInit();
    expect(save).toHaveBeenCalledTimes(1);
    const user = save.mock.calls[0][0];
    expect(user.role).toBe(UserRole.ADMIN);
    expect(user.passwordHash).not.toBe('Clave-Segura-2026');
    await expect(
      passwordsMatch('Clave-Segura-2026', user.passwordHash),
    ).resolves.toBe(true);
    await expect(passwordsMatch('Admin1234', user.passwordHash)).resolves.toBe(
      false,
    );
  });

  it('leaves an existing admin untouched', async () => {
    const { seed, save } = build({ ADMIN_PASSWORD: 'Clave-Segura-2026' }, {
      role: UserRole.ADMIN,
    } as User);
    await seed.onModuleInit();
    expect(save).not.toHaveBeenCalled();
  });
});
