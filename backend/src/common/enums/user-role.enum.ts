export enum UserRole {
  REQUESTER = 'requester',
  DISPATCHER = 'dispatcher',
  FLEET_OPERATOR = 'fleet_operator',
  ADMIN = 'admin',
}

export const PUBLIC_REGISTER_ROLES: UserRole[] = [UserRole.REQUESTER];

export const INSTITUTIONAL_ROLES: UserRole[] = [
  UserRole.DISPATCHER,
  UserRole.FLEET_OPERATOR,
];
