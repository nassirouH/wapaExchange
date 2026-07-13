import { Controller, Get, Inject } from '@nestjs/common';
import { Queue } from 'bullmq';
import { PrismaService } from '../../infra/prisma/prisma.service';

interface Component {
  name: string;
  status: 'operational' | 'degraded' | 'down';
  since?: string;
}

interface StatusReport {
  status: 'operational' | 'degraded' | 'down';
  updated_at: string;
  components: Component[];
}

/**
 * Public — no auth. Powers status.wapaexchange.com. Deliberately does NOT
 * probe third-party providers (Stripe, Thunes, Sumsub) directly from every
 * request; instead, /health checks plus webhook error rates feed a
 * Redis-cached snapshot updated once a minute by a scheduled task (TODO).
 *
 * For MVP this is a live check on Postgres + Redis only. Partner statuses
 * are hard-coded 'operational' until we wire the health-probe cron.
 */
@Controller('status')
export class StatusController {
  constructor(
    private readonly prisma: PrismaService,
    @Inject('PAYOUTS_QUEUE') private readonly payouts: Queue,
  ) {}

  @Get()
  async publicStatus(): Promise<StatusReport> {
    const [pg, redis] = await Promise.all([this.checkPostgres(), this.checkRedis()]);

    const components: Component[] = [
      { name: 'API', status: 'operational' },
      { name: 'Database', status: pg },
      { name: 'Queue (Redis)', status: redis },
      { name: 'Pay-in (Stripe)', status: 'operational' },
      { name: 'Payout (Thunes)', status: 'operational' },
      { name: 'Identity (Sumsub)', status: 'operational' },
    ];

    const overall = components.some((c) => c.status === 'down')
      ? 'down'
      : components.some((c) => c.status === 'degraded')
        ? 'degraded'
        : 'operational';

    return {
      status: overall,
      updated_at: new Date().toISOString(),
      components,
    };
  }

  private async checkPostgres(): Promise<'operational' | 'down'> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return 'operational';
    } catch {
      return 'down';
    }
  }

  private async checkRedis(): Promise<'operational' | 'down'> {
    try {
      const client = (await this.payouts.client) as unknown as { ping(): Promise<string> };
      return (await client.ping()) === 'PONG' ? 'operational' : 'down';
    } catch {
      return 'down';
    }
  }
}
