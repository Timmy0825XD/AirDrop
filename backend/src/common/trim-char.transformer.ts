import { ValueTransformer } from 'typeorm';

/** Postgres CHAR pads with spaces; bcrypt/SHA hashes must not keep that padding. */
export class TrimCharTransformer implements ValueTransformer {
  to(value: string | null): string | null {
    return value;
  }

  from(value: string | null): string | null {
    return value?.trim() ?? null;
  }
}
