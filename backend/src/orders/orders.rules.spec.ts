import { BadRequestException } from '@nestjs/common';
import { DocumentType } from '../common/enums/document-type.enum';
import { SaleType } from '../common/enums/sale-type.enum';
import { User } from '../users/user.entity';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PlanFrequency } from '../common/enums/plan-frequency.enum';
import { PlanStatus } from '../common/enums/plan-status.enum';
import {
  DOCUMENT_MISMATCH,
  FORMULA_NOT_FOR_TRANSFER,
  PLAN_WINDOW_DAYS,
  ONLY_RECEIVED_IS_REJECTED,
  addCalendarDays,
  occurrenceDates,
  renewalDue,
  windowEnd,
  isUnattendedEmergency,
  UNATTENDED_EMERGENCY_MS,
  PRESCRIPTION_IMAGE_REQUIRED,
  SPECIAL_CONTROL_MESSAGE,
  assertNoPatientFormula,
  assertStillReceived,
  patientFormula,
} from './orders.rules';

describe('patientFormula', () => {
  const requester = {
    documentType: DocumentType.CITIZENSHIP_ID,
    documentNumber: '1098765432',
  } as User;
  const jpeg = Buffer.from('formula').toString('base64');

  it('rejects special control and a prescription without an image', () => {
    expect(() =>
      patientFormula(requester, SaleType.SPECIAL_CONTROL, {}),
    ).toThrow(new BadRequestException(SPECIAL_CONTROL_MESSAGE));
    expect(() =>
      patientFormula(requester, SaleType.PRESCRIPTION, {
        patientDocumentType: DocumentType.CITIZENSHIP_ID,
        patientDocumentNumber: '1098765432',
      }),
    ).toThrow(new BadRequestException(PRESCRIPTION_IMAGE_REQUIRED));
  });

  it('rejects a document that is not the account document', () => {
    expect(() =>
      patientFormula(requester, SaleType.PRESCRIPTION, {
        patientDocumentType: DocumentType.CITIZENSHIP_ID,
        patientDocumentNumber: '1098765433',
        prescriptionMime: 'image/jpeg',
        prescriptionImageBase64: jpeg,
      }),
    ).toThrow(new BadRequestException(DOCUMENT_MISMATCH));
  });

  it('rejects a patient formula on a hub transfer', () => {
    expect(() =>
      assertNoPatientFormula({
        saleType: SaleType.OVER_THE_COUNTER,
        prescriptionImageBase64: jpeg,
      }),
    ).toThrow(new BadRequestException(FORMULA_NOT_FOR_TRANSFER));
  });
});

describe('assertStillReceived', () => {
  it('allows received and blocks any later status', () => {
    expect(() => assertStillReceived(OrderStatus.RECEIVED)).not.toThrow();
    expect(() => assertStillReceived(OrderStatus.REJECTED)).toThrow(
      new BadRequestException(ONLY_RECEIVED_IS_REJECTED),
    );
    expect(() => assertStillReceived(OrderStatus.PENDING_LOAD)).toThrow(
      new BadRequestException(ONLY_RECEIVED_IS_REJECTED),
    );
  });
});

describe('occurrenceDates', () => {
  const start = '2026-10-05';

  it('fills eight weekly dates inside 56 days and leaves the next window out', () => {
    const dates = occurrenceDates(
      start,
      windowEnd(start),
      PlanFrequency.WEEKLY,
    );
    expect(dates).toHaveLength(8);
    expect(dates[0]).toBe(start);
    expect(dates[7]).toBe(addCalendarDays(start, 49));
    expect(dates).not.toContain(addCalendarDays(start, PLAN_WINDOW_DAYS));
  });

  it('keeps a single date for once and clamps a month-end to the last day', () => {
    expect(
      occurrenceDates(start, windowEnd(start), PlanFrequency.ONCE),
    ).toEqual([start]);
    expect(
      occurrenceDates(
        '2026-01-31',
        windowEnd('2026-01-31'),
        PlanFrequency.MONTHLY,
      ),
    ).toEqual(['2026-01-31', '2026-02-28']);
  });

  it('asks to extend only in the last week of an active repeating plan', () => {
    const windowEndsOn = '2026-11-30';
    const plan = {
      status: PlanStatus.ACTIVE,
      frequency: PlanFrequency.WEEKLY,
      windowEndsOn,
    };
    expect(renewalDue(plan, '2026-11-22')).toBe(false);
    expect(renewalDue(plan, '2026-11-23')).toBe(true);
    expect(renewalDue(plan, '2026-12-01')).toBe(true);
    expect(
      renewalDue({ ...plan, frequency: PlanFrequency.ONCE }, '2026-12-01'),
    ).toBe(false);
  });
});

describe('isUnattendedEmergency', () => {
  const now = new Date('2026-10-04T12:00:00.000Z');

  it('flags an emergency only after five minutes in received', () => {
    expect(
      isUnattendedEmergency(
        new Date(now.getTime() - UNATTENDED_EMERGENCY_MS),
        now,
      ),
    ).toBe(false);
    expect(
      isUnattendedEmergency(
        new Date(now.getTime() - UNATTENDED_EMERGENCY_MS - 1),
        now,
      ),
    ).toBe(true);
  });
});
