import { Injectable, Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../prisma/prisma.service';
import { ThunesClient } from '../../integrations/thunes/thunes.client';
import type { PayoutJobData } from './queue.module';

@Injectable()
export class PayoutsProcessor {
  private readonly logger = new Logger(PayoutsProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly thunes: ThunesClient,
  ) {}

  async process(job: Job<PayoutJobData>): Promise<void> {
    const { transferId } = job.data;

    const transfer = await this.prisma.transfer.findUnique({
      where: { id: transferId },
      include: { recipient: true },
    });
    if (!transfer) throw new Error(`Transfer ${transferId} not found.`);
    if (transfer.status !== 'payin_received') {
      this.logger.warn(`Skipping payout for ${transferId}: status=${transfer.status}`);
      return;
    }

    try {
      const result = await this.thunes.createPayout({
        externalId: transfer.id,
        destinationCountry: transfer.recipient.country,
        receiveCurrency: 'XOF', // TODO: derive from quote / recipient
        receiveAmount: Number(transfer.receiveAmount),
        payoutMethod: transfer.recipient.payoutMethod,
        mobileMoneyProvider: transfer.recipient.mobileMoneyProvider,
        mobileMoneyNumber: transfer.recipient.mobileMoneyNumber,
        bankName: transfer.recipient.bankName,
        bankAccountNumber: transfer.recipient.bankAccountNumber,
        recipientFullName: transfer.recipient.fullName,
      });

      await this.prisma.$transaction([
        this.prisma.transfer.update({
          where: { id: transferId },
          data: {
            status: 'forwarded',
            payoutProvider: 'thunes',
            payoutReference: result.partnerTransactionId,
          },
        }),
        this.prisma.transferEvent.create({
          data: {
            transferId,
            fromStatus: 'payin_received',
            toStatus: 'forwarded',
            source: 'worker:payouts',
            metadata: { thunes: result },
          },
        }),
      ]);
    } catch (err) {
      this.logger.error(`Payout failed for ${transferId}`, err);
      // BullMQ retries up to PAYOUT_JOB_OPTIONS.attempts. On final failure,
      // a separate listener should refund the pay-in. (TODO)
      throw err;
    }
  }
}
