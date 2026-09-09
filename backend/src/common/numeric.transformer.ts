import { ValueTransformer } from 'typeorm';

/** Postgres `numeric` llega como string; el dominio usa number. */
export const NUMERIC_TRANSFORMER: ValueTransformer = {
  to: (value: number | null) => value,
  from: (value: string | number | null) =>
    value == null || value === '' ? null : Number(value),
};
