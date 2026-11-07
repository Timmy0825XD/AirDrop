import { IsIn } from 'class-validator';
import type { GeneratedKind } from '../sim-actors.rules';

const KINDS: GeneratedKind[] = ['emergency', 'scheduled'];

/** CU-39: el generador crea una urgencia o un programado. */
export class GenerateOrderDto {
  @IsIn(KINDS, { message: 'El pedido debe ser una urgencia o un programado.' })
  kind: GeneratedKind;
}
