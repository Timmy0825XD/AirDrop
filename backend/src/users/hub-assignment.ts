import { User } from './user.entity';

export function assignedHubIds(user: User): string[] {
  return (user.hubAssignments ?? []).map((assignment) => assignment.hubId);
}
