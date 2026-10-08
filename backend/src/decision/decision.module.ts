import { Module } from '@nestjs/common';
import { HubsModule } from '../hubs/hubs.module';
import { RoutingModule } from '../routing/routing.module';
import { DecisionService } from './decision.service';
import { EligibilityService } from './eligibility.service';

@Module({
  imports: [HubsModule, RoutingModule],
  providers: [DecisionService, EligibilityService],
  exports: [DecisionService],
})
export class DecisionModule {}
