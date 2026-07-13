import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  Inject,
} from '@nestjs/common';
import { Queue } from 'bullmq';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { StripeService } from '../../integrations/stripe/stripe.service';
import { PAYOUT_JOB_OPTIONS, type PayoutJobData } from '../../infra/queue/queue.module';

interface CreateInput {
  quote_id: string;
  recipient_id: string;
  payin_method: 'apple_pay' | 'card' | 'sepa' | 'open_banking';
}

@Injectable()
export class TransfersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly stripe: StripeService,
    @Inject('PAYOUTS_QUEUE') private readonly payouts: Queue<PayoutJobData>,
  ) {}

  async create(userId: string, input: CreateInput) {
    const quote = await this.prisma.quote.findFirst({
      where: { id: input.quote_id, userId },
      include: { transfer: true },
    });
    if (!quote) throw new NotFoundException('Quote not found.');
    if (quote.transfer) throw new ConflictException('Quote already used.');
    if (quote.expiresAt < new Date()) throw new BadRequestException('Quote expired.');

    const recipient = await this.prisma.recipient.findFirst({
      where: { id: input.recipient_id, userId, deletedAt: null },
    });
    if (!recipient) throw new NotFoundException('Recipient not found.');
    if (recipient.country !== quote.destinationCountry || recipient.payoutMethod !== quote.payoutMethod) {
      throw new BadRequestException('Recipient does not match quote corridor.');
    }

    const transfer = await this.prisma.transfer.create({
      data: {
        userId,
        quoteId: quote.id,
        recipientId: recipient.id,
        payoutCountry: quote.destinationCountry,
        sendAmount: quote.sendAmount,
        receiveAmount: quote.receiveAmount,
        feeAmount: quote.feeAmount,
        fxRate: quote.fxRate,
        payinProvider: 'stripe',
      },
    });

    const intent = await this.stripe.createPayinIntent({
      transferId: transfer.id,
      userId,
      amount: Number(quote.totalPay),
      method: input.payin_method,
    });

    await this.prisma.transfer.update({
      where: { id: transfer.id },
      data: { payinReference: intent.id },
    });

    return {
      transfer: this.serialize(transfer, recipient, quote.receiveCurrency),
      payin_client_secret: intent.client_secret,
    };
  }

  /**
   * Called by the Stripe webhook once `payment_intent.succeeded` fires.
   * Enqueues a payout job; the worker will call Thunes asynchronously.
   */
  async enqueuePayout(transferId: string) {
    await this.payouts.add(
      'create-payout',
      { transferId },
      { ...PAYOUT_JOB_OPTIONS, jobId: `payout:${transferId}` }, // dedupes per transfer
    );
  }

  async listForUser(userId: string) {
    const rows = await this.prisma.transfer.findMany({
      where: { userId },
      include: { recipient: true, quote: true },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => this.serialize(r, r.recipient, r.quote.receiveCurrency));
  }

  async detail(userId: string, id: string) {
    const r = await this.prisma.transfer.findFirst({
      where: { id, userId },
      include: { recipient: true, quote: true },
    });
    if (!r) throw new NotFoundException();
    return this.serialize(r, r.recipient, r.quote.receiveCurrency);
  }

  async cancel(userId: string, id: string) {
    const r = await this.prisma.transfer.findFirst({
      where: { id, userId },
      include: { quote: true },
    });
    if (!r) throw new NotFoundException();
    if (r.status !== 'pending_payin') {
      throw new ConflictException('Transfer can no longer be cancelled.');
    }
    const updated = await this.prisma.transfer.update({
      where: { id },
      data: { status: 'refunded' },
    });
    const recipient = await this.prisma.recipient.findUniqueOrThrow({ where: { id: r.recipientId } });
    return this.serialize(updated, recipient, r.quote.receiveCurrency);
  }

  private serialize(t: any, recipient: any, receiveCurrency: string) {
    return {
      id: t.id,
      recipient_name: recipient.fullName,
      recipient_country: recipient.country,
      send_currency: 'EUR',
      send_amount: t.sendAmount,
      receive_currency: receiveCurrency,
      receive_amount: t.receiveAmount,
      fee_amount: t.feeAmount,
      status: t.status,
      payout_method: recipient.payoutMethod,
      created_at: t.createdAt,
    };
  }
}
