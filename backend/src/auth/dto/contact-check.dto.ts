import { Allow, Validate } from 'class-validator';
import { Transform } from 'class-transformer';
import { EmailOrPhoneConstraint } from './email-or-phone.decorator';

/** Always present after transform so EmailOrPhone is not skipped by @IsOptional. */
export class ContactCheckDto {
  @Allow()
  @Transform(() => true)
  @Validate(EmailOrPhoneConstraint)
  contactCheck?: boolean;
}
