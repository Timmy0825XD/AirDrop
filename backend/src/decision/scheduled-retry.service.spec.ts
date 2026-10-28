import { Repository } from 'typeorm';
import { Order } from '../orders/order.entity';
import { DecisionService } from './decision.service';
import { ScheduledRetryService } from './scheduled-retry.service';

const now = new Date('2026-10-16T15:00:00.000Z');

function build(due: Array<{ id: string }>) {
  const orders = {
    find: jest.fn().mockResolvedValue(due),
    update: jest.fn().mockResolvedValue({ affected: 1 }),
  };
  const decision = { retryScheduled: jest.fn().mockResolvedValue(null) };
  const service = new ScheduledRetryService(
    orders as unknown as Repository<Order>,
    decision as unknown as DecisionService,
  );
  return { service, orders, decision };
}

describe('ScheduledRetryService', () => {
  it('asks the decision engine to retry every due order', async () => {
    const { service, decision } = build([{ id: 'a' }, { id: 'b' }]);
    await service.runDue(now);
    expect(decision.retryScheduled).toHaveBeenCalledWith('a', now);
    expect(decision.retryScheduled).toHaveBeenCalledWith('b', now);
  });

  it('pushes the next try forward when a retry fails, and keeps going', async () => {
    const { service, decision, orders } = build([{ id: 'a' }, { id: 'b' }]);
    decision.retryScheduled.mockRejectedValueOnce(new Error('caída'));
    await service.runDue(now);
    expect(orders.update).toHaveBeenCalledWith(
      { id: 'a', fallbackKind: 'retry' },
      { retryAfter: new Date(now.getTime() + 15 * 60 * 1000) },
    );
    expect(decision.retryScheduled).toHaveBeenCalledWith('b', now);
  });
});
