import { ValidationOptions, registerDecorator } from 'class-validator';
import { todayInColombia } from '../../orders/orders.rules';

export const ESTIMATED_END_NOT_PAST =
  'La fecha estimada no puede ser anterior a hoy.';

/** Fecha AAAA-MM-DD de hoy en adelante, con el día de Colombia. */
export function IsTodayOrLater(options?: ValidationOptions): PropertyDecorator {
  return (target, propertyName) => {
    registerDecorator({
      name: 'isTodayOrLater',
      target: target.constructor,
      propertyName: propertyName as string,
      options: { message: ESTIMATED_END_NOT_PAST, ...options },
      validator: {
        validate: (value: unknown) =>
          typeof value !== 'string' || value >= todayInColombia(),
      },
    });
  };
}
