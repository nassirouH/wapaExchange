import { Controller, Get, HttpCode, Inject, ServiceUnavailableException } from '@nestjs/common';
import { Queue } from 'bullmq';
import { PrismaService } from '../../infra/prisma/prisma.service';

interface HealthReport {
  status: 'ok' | 'degraded';
  timestamp: string;
  uptime_seconds: number;
  checks: {
    postgres: 'ok' | 'fail';
    redis: 'ok' | 'fail';
  };
}

/**
 * Public, unauthenticated. Used by ALB/ECS health checks AND by humans.
 * - `GET /v1/health/liveness` — process is up. Cheap, always 200.
 * - `GET /v1/health` — readiness. Verifies Postgres + Redis. Returns 503 if either is down.
 */
@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    @Inject('PAYOUTS_QUEUE') private readonly payouts: Queue,
  ) {}

  @Get('liveness')
  @HttpCode(200)
  liveness() {
    return { status: 'ok', timestamp: new Date().toISOString() };
  }

  @Get()
  async readiness(): Promise<HealthReport> {
    const pg = await this.checkPostgres();
    const redis = await this.checkRedis();
    const report: HealthReport = {
      status: pg === 'ok' && redis === 'ok' ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime_seconds: Math.round(process.uptime()),
      checks: { postgres: pg, redis: redis },
    };
    if (report.status !== 'ok') throw new ServiceUnavailableException(report);
    return report;
  }

  private async checkPostgres(): Promise<'ok' | 'fail'> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return 'ok';
    } catch {
      return 'fail';
    }
  }

  private async checkRedis(): Promise<'ok' | 'fail'> {
    try {
      // BullMQ exposes the underlying ioredis client via `client`.
      const client = await this.payouts.client;
      const reply = await client.ping();
      return reply === 'PONG' ? 'ok' : 'fail';
    } catch {
      return 'fail';
    }
  }
}
