import { IsEnum, IsIn, IsOptional, IsUUID } from 'class-validator';
import {
  INSTITUTIONAL_ROLES,
  UserRole,
} from '../../common/enums/user-role.enum';
import { UserStatus } from '../../common/enums/user-status.enum';

export class ListInstitutionalUsersQueryDto {
  @IsOptional()
  @IsIn(INSTITUTIONAL_ROLES, {
    message: 'El rol debe ser dispatcher o fleet_operator.',
  })
  role?: UserRole;

  @IsOptional()
  @IsEnum(UserStatus, { message: 'El estado no es válido.' })
  status?: UserStatus;

  @IsOptional()
  @IsUUID('4', { message: 'La central no es válida.' })
  hubId?: string;
}
