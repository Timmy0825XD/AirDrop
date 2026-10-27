import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from '../orders/order.entity';
import { assignedHubIds } from '../users/hub-assignment';
import { User } from '../users/user.entity';
import { TelemetryAccess, telemetryAccess } from './telemetry.rules';

@Injectable()
export class TelemetryAccessService {
  constructor(
    @InjectRepository(Order)
    private readonly orders: Repository<Order>,
    @InjectRepository(User)
    private readonly users: Repository<User>,
  ) {}

  findUser(id: string): Promise<User | null> {
    return this.users.findOne({
      where: { id },
      relations: { hubAssignments: true },
    });
  }

  async resolve(user: User, orderId: string): Promise<TelemetryAccess | null> {
    const order = await this.orders.findOne({ where: { id: orderId } });
    if (!order) {
      return null;
    }
    return telemetryAccess(
      { id: user.id, role: user.role, hubIds: assignedHubIds(user) },
      {
        requesterId: order.requesterId,
        originHubId: order.originHubId,
        destinationHubId: order.destinationHubId,
      },
    );
  }
}
