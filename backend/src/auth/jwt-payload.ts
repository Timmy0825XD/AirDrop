import { UserRole } from '../common/enums/user-role.enum';

export type JwtPayload = {
  sub: string;
  role: UserRole;
};
