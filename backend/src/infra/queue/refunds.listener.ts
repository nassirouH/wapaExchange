import { Inject, Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { Queue, QueueEvents } from 'bullmq';
import { PrismaService } from '../prisma/prisma.service';
import { StripeService } from '../../integrations/stripe/stripe.service';
import { PAYOUTS_QUEUE } from './queue.module';

/**
 * Listens for the BullMQ `failed` event on the payouts queue and, when a job
 * has exhausted all its retries, refunds the pay-in PaymentIntent and marks
 * the transfer as `refunded`.
 *
 * Only registered when ROLE=worker so the API containers don't double-refund.
 */
@Injectable()
export class RefundsListener implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RefundsListener.name);
  private events?: QueueEvents;

  constructor(
    @Inject('PAYOUTS_QUEUE') private readonly queue: Queue,
    private readonly prisma: PrismaService,
    private readonly stripe: StripeService,
  ) {}

  async onModuleInit() {
    const conn = (this.queue.opts as { connection?: unknown }).connection;
    this.events = new QueueEvents(PAYOUTS_QUEUE, { connection: conn as never });

    // `failed` fires on every failed attempt; we only act on the final one.
    this.events.on('failed', async ({ jobId, failedReason, prev }) => {
      const job = await this.queue.getJob(jobId);
      if (!job) return;
      const attemptsMade = job.attemptsMade ?? 0;
      const maxAttempts = job.opts.attempts ?? 1;
      if (attemptsMade < maxAttempts) return; // not yet exhausted

      const transferId = job.data?.transferId as string | undefined;
      if (!transferId) return;
      this.logger.warn(
        `Payout job for transfer ${transferId} exhausted ${maxAttempts} attempts (last error: ${failedReason}). Refunding pay-in.`,
      );
      try {
        await this.refundTransfer(transferId, failedReason, prev);
      } catch (err) {
        this.logger.error(`Refund flow failed for transfer ${transferId}`, err);
      }
    });
  }

  async onModuleDestroy() {
    await this.events?.close();
  }

  private async refundTransfer(transferId: string, failureReason: string, lastStatus: string | undefined) {
    const transfer = await this.prisma.transfer.findUnique({ where: { id: transferId } });
    if (!transfer) return;
    if (!transfer.payinReference) {
      this.logger.error(`Transfer ${transferId} has no payin_reference — cannot refund.`);
      return;
    }
    if (transfer.status === 'refunded') return; // idempotency: already done

    const refund = await this.stripe.refundPayinIntent(
      transfer.payinReference,
      `refund:${transferId}`, // idempotency key — Stripe dedupes
    );

    await this.prisma.$transaction([
      this.prisma.transfer.update({
        where: { id: transferId },
        data: { status: 'refunded', failureCode: 'payout_exhausted' },
      }),
      this.prisma.transferEvent.create({
        data: {
          transferId,
          fromStatus: transfer.status,
          toStatus: 'refunded',
          source: 'worker:refunds',
          metadata: {
            failure_reason: failureReason,
            last_status: lastStatus ?? null,
            stripe_refund: refund,
          },
        },
      }),
    ]);
  }
}
