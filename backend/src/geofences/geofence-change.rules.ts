import { FieldChange } from './geofence-change.entity';
import { PublicGeofence } from './geofence.presenter';

/** Lo que el historial compara. El polígono se resume en `geometry`. */
const TRACKED = [
  'class',
  'name',
  'legalBasis',
  'source',
  'shape',
  'center',
  'radiusM',
  'active',
] as const;

/** RU-36: solo los campos que de verdad cambiaron. */
export function diffGeofence(
  before: PublicGeofence,
  after: PublicGeofence,
): Record<string, FieldChange> {
  const changes: Record<string, FieldChange> = {};
  for (const field of TRACKED) {
    if (JSON.stringify(before[field]) !== JSON.stringify(after[field])) {
      changes[field] = { from: before[field], to: after[field] };
    }
  }
  if (JSON.stringify(before.polygon) !== JSON.stringify(after.polygon)) {
    changes.geometry = { from: 'anterior', to: 'nueva' };
  }
  return changes;
}
