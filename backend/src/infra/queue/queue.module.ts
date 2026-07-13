import { Global, Module, Provider } from '@nestjs/common';
import { Queue, Worker, JobsOptions, ConnectionOptions } from 'bullmq';
import { PayoutsProcessor } from './payouts.processor';

export const PAYOUTS_QUEUE = 'payouts';

/**
 * The Queue (for enqueueing) is always provided so any container can produce jobs.
 * The Worker (which actually processes) is only registered when ROLE=worker,
 * so the API containers don't double-consume jobs.
 *
 * Set ROLE=worker for the worker ECS service; leave unset for API.
 */
const isWorker = process.env.ROLE === 'worker';

/**
 * Parse REDIS_URL into a BullMQ connection options object.
 * Passing an `ioredis.Redis` instance directly conflicts with BullMQ's bundled ioredis types,
 * so we hand BullMQ a plain options object and let it construct its own client.
 */
function redisConnection(): ConnectionOptions {
  const url = new URL(process.env.REDIS_URL ?? 'redis://localhost:6379');
  return {
    host: url.hostname,
    port: Number(url.port || 6379),
    password: url.password || undefined,
    username: url.username || undefined,
    db: url.pathname && url.pathname !== '/' ? Number(url.pathname.slice(1)) : undefined,
    maxRetriesPerRequest: null,
  };
}

const baseProviders: Provider[] = [
  {
    provide: 'PAYOUTS_QUEUE',
    useFactory: () => new Queue(PAYOUTS_QUEUE, { connection: redisConnection() }),
  },
];

const workerProviders: Provider[] = [
  PayoutsProcessor,
  {
    provide: 'PAYOUTS_WORKER',
    inject: [PayoutsProcessor],
    useFactory: (processor: PayoutsProcessor) =>
      new Worker(
        PAYOUTS_QUEUE,
        (job) => processor.process(job),
        {
          connection: redisConnection(),
          concurrency: 4,
          removeOnComplete: { count: 1000 },
          removeOnFail: { count: 5000 },
        },
      ),
  },
];

@Global()
@Module({
  providers: isWorker ? [...baseProviders, ...workerProviders] : baseProviders,
  exports: ['PAYOUTS_QUEUE'],
})
export class QueueModule {}

export const PAYOUT_JOB_OPTIONS: JobsOptions = {
  attempts: 5,
  backoff: { type: 'exponential', delay: 5_000 },
  removeOnComplete: 1000,
  removeOnFail: 5000,
};

export interface PayoutJobData {
  transferId: string;
}
