import { ValidationOptions, registerDecorator } from 'class-validator';
import { todayInColombia } from '../../orders/orders.rules';

export const EXPIRATION_MUST_BE_FUTURE =
  'La fecha de vencimiento debe ser posterior a hoy.';

/** Fecha AAAA-MM-DD estrictamente posterior al día de hoy en Colombia. */
export function IsAfterToday(options?: ValidationOptions): PropertyDecorator {
  return (target, propertyName) => {
    registerDecorator({
      name: 'isAfterToday',
      target: target.constructor,
      propertyName: propertyName as string,
      options: { message: EXPIRATION_MUST_BE_FUTURE, ...options },
      validator: {
        validate: (value: unknown) =>
          typeof value !== 'string' || value > todayInColombia(),
      },
    });
  };
}
