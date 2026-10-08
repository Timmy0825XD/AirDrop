import { Injectable } from '@nestjs/common';
import { chooseDrone } from './decision.rules';

@Injectable()
export class EligibilityService {
  choose(
    input: Parameters<typeof chooseDrone>[0],
  ): ReturnType<typeof chooseDrone> {
    return chooseDrone(input);
  }
}
