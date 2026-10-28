import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HubsModule } from '../hubs/hubs.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { Order } from '../orders/order.entity';
import { RoutingModule } from '../routing/routing.module';
import { SimulationModule } from '../simulation/simulation.module';
import { DecisionService } from './decision.service';
import { EligibilityService } from './eligibility.service';
import { FallbackService } from './fallback.service';
import { HubEvaluationService } from './hub-evaluation.service';
import { ScheduledRetryService } from './scheduled-retry.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order]),
    HubsModule,
    RoutingModule,
    SimulationModule,
    NotificationsModule,
  ],
  providers: [
    DecisionService,
    EligibilityService,
    HubEvaluationService,
    FallbackService,
    ScheduledRetryService,
  ],
  exports: [DecisionService],
})
export class DecisionModule {}
