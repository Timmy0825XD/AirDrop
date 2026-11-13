import { SaleType } from '../common/enums/sale-type.enum';
import { Order } from './order.entity';

export function presentOrder(order: Order) {
  return {
    id: order.id,
    missionType: order.missionType,
    destinationKind: order.destinationKind,
    status: order.status,
    priority: order.priority,
    medicationName: order.medicationName,
    saleType: order.saleType,
    requiresColdChain: order.requiresColdChain,
    coldChainAlert: order.coldChainAlertAt != null,
    coldChainAlertAt: order.coldChainAlertAt,
    quantity: order.quantity,
    description: order.description,
    requesterId: order.requesterId,
    createdByUserId: order.createdByUserId,
    destinationHubId: order.destinationHubId,
    originHubId: order.originHubId,
    address: order.address,
    latitude: order.latitude,
    longitude: order.longitude,
    droneId: order.droneId,
    authorizedAt: order.authorizedAt,
    autoDispatched: order.autoDispatched ?? false,
    loadConfirmedAt: order.loadConfirmedAt,
    dispatchedLot: order.dispatchedLot,
    dispatchedLotExpiresOn: order.dispatchedLotExpiresOn,
    returnCheckedAt: order.returnCheckedAt,
    returnOutcome: order.returnOutcome,
    receiptRejectedReason: order.receiptRejectedReason,
    statusReason: order.statusReason,
    planId: order.planId,
    scheduledFor: order.scheduledFor,
    scheduledAt: order.scheduledAt ?? null,
    windowEndsAt: order.windowEndsAt ?? null,
    confirmedAt: order.confirmedAt ?? null,
    hasPrescription: order.saleType === SaleType.PRESCRIPTION,
    triage: presentTriage(order),
    allergies: order.allergies ?? null,
    patient: presentPatient(order),
    reassignedFromHubId: order.reassignedFromHubId,
    fallback: presentFallback(order),
    createdAt: order.createdAt,
  };
}

/**
 * RF-41: el tamizaje, para el despachador que decide y para quien pidió.
 * `null` en un pedido sin tamizaje.
 */
function presentTriage(order: Order) {
  if (!order.patientGroup) {
    return null;
  }
  return {
    redFlags: order.redFlags ?? [],
    patientGroup: order.patientGroup,
    pregnant: order.pregnant ?? null,
    symptoms: order.symptoms ?? [],
    onset: order.symptomOnset,
    severity: order.symptomSeverity,
  };
}

/** RF-42: el paciente a cargo; `null` si el paciente es el titular. */
function presentPatient(order: Order) {
  if (!order.patientFullName) {
    return null;
  }
  return {
    fullName: order.patientFullName,
    documentType: order.patientDocumentType,
    documentNumber: order.patientDocumentNumber,
    relation: order.patientRelation,
  };
}

/** RF-18 y CU-05: la alternativa que ve quien pidió, mientras aplica. */
function presentFallback(order: Order) {
  if (!order.fallbackKind) {
    return null;
  }
  return {
    kind: order.fallbackKind,
    reason: order.fallbackReason,
    options: order.fallbackOptions ?? [],
    retryAfter: order.retryAfter,
    reassignedAt: order.reassignedAt,
  };
}
