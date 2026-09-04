import {
  ValidatorConstraint,
  ValidatorConstraintInterface,
  ValidationArguments,
} from 'class-validator';

@ValidatorConstraint({ name: 'emailOrPhone', async: false })
export class EmailOrPhoneConstraint implements ValidatorConstraintInterface {
  validate(_: unknown, args: ValidationArguments): boolean {
    const obj = args.object as { email?: string; phone?: string };
    return Boolean(obj.email || obj.phone);
  }

  defaultMessage(): string {
    return 'Indica un correo o un celular.';
  }
}
