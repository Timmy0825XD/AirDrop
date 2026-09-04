export enum UserRole {
  REQUESTER = 'requester',
  DISPATCHER = 'dispatcher',
  FLEET_OPERATOR = 'fleet_operator',
  RECIPIENT = 'recipient',
  ADMIN = 'admin',
}

export const PUBLIC_REGISTER_ROLES: UserRole[] = [
  UserRole.REQUESTER,
  UserRole.DISPATCHER,
  UserRole.FLEET_OPERATOR,
  UserRole.RECIPIENT,
];
