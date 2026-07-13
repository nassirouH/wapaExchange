import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { TransfersService } from './transfers.service';

interface QuoteRow {
  id: string;
  userId: string;
  sendCurrency: string;
  sendAmount: number;
  receiveCurrency: string;
  receiveAmount: number;
  feeAmount: number;
  fxRate: number;
  totalPay: number;
  destinationCountry: string;
  payoutMethod: 'mobile_money' | 'bank_transfer';
  expiresAt: Date;
  transfer: null | { id: string };
}

interface RecipientRow {
  id: string;
  userId: string;
  fullName: string;
  country: string;
  payoutMethod: 'mobile_money' | 'bank_transfer';
  deletedAt: null | Date;
}

interface TransferRow {
  id: string;
  userId: string;
  quoteId: string;
  recipientId: string;
  status: string;
  sendAmount: number;
  receiveAmount: number;
  feeAmount: number;
  fxRate: number;
  payinProvider: string | null;
  payinReference: string | null;
  payoutCountry: string;
  failureCode: string | null;
  createdAt: Date;
}

function makeFixtures() {
  const quote: QuoteRow = {
    id: 'q1', userId: 'u1', sendCurrency: 'EUR', sendAmount: 200, receiveCurrency: 'XOF',
    receiveAmount: 129_880.08, feeAmount: 1.99, fxRate: 649.4, totalPay: 201.99,
    destinationCountry: 'SN', payoutMethod: 'mobile_money',
    expiresAt: new Date(Date.now() + 5 * 60_000), transfer: null,
  };
  const recipient: RecipientRow = {
    id: 'r1', userId: 'u1', fullName: 'Aicha Diallo', country: 'SN',
    payoutMethod: 'mobile_money', deletedAt: null,
  };
  return { quote, recipient };
}

function makePrismaMock(quote: QuoteRow | null, recipient: RecipientRow | null) {
  const transfers = new Map<string, TransferRow>();
  let seq = 0;
  return {
    transfers,
    quote: { findFirst: jest.fn(async () => quote) },
    recipient: {
      findFirst: jest.fn(async () => recipient),
      findUniqueOrThrow: jest.fn(async () => recipient!),
    },
    transfer: {
      create: jest.fn(async ({ data }: { data: Record<string, unknown> }) => {
        const row: TransferRow = {
          id: `tx_${++seq}`, userId: data.userId as string, quoteId: data.quoteId as string,
          recipientId: data.recipientId as string, status: 'pending_payin',
          sendAmount: data.sendAmount as number, receiveAmount: data.receiveAmount as number,
          feeAmount: data.feeAmount as number, fxRate: data.fxRate as number,
          payinProvider: (data.payinProvider as string) ?? null, payinReference: null,
          payoutCountry: data.payoutCountry as string, failureCode: null, createdAt: new Date(),
        };
        transfers.set(row.id, row);
        return row;
      }),
      update: jest.fn(async ({ where, data }: { where: { id: string }; data: Record<string, unknown> }) => {
        const t = transfers.get(where.id)!;
        Object.assign(t, data);
        return t;
      }),
      findFirst: jest.fn(async ({ where }: { where: { id: string } }) => transfers.get(where.id) ?? null),
    },
  };
}

function makeStripeMock(intentId = 'pi_test_123', secret = 'pi_test_123_secret_x') {
  return {
    createPayinIntent: jest.fn(async () => ({ id: intentId, client_secret: secret, status: 'requires_payment_method' })),
    refundPayinIntent: jest.fn(async () => ({ id: 're_test', status: 'succeeded' })),
  };
}

function makeComplianceMock(result: { blocked: boolean; hits: number } = { blocked: false, hits: 0 }) {
  return { evaluateTransfer: jest.fn(async () => result) };
}

function makeQueueMock() {
  return { add: jest.fn(async () => ({ id: 'job_1' })) };
}

function makeService(opts: {
  quote: QuoteRow | null;
  recipient: RecipientRow | null;
  compliance?: { blocked: boolean; hits: number };
}) {
  const prisma = makePrismaMock(opts.quote, opts.recipient);
  const stripe = makeStripeMock();
  const compliance = makeComplianceMock(opts.compliance);
  const queue = makeQueueMock();
  const service = new TransfersService(prisma as never, stripe as never, compliance as never, queue as never);
  return { service, prisma, stripe, compliance, queue };
}

describe('TransfersService.create', () => {
  it('happy path: creates transfer, calls Stripe, persists payin_reference, returns client_secret', async () => {
    const { quote, recipient } = makeFixtures();
    const { service, prisma, stripe } = makeService({ quote, recipient });

    const result = await service.create('u1', {
      quote_id: 'q1', recipient_id: 'r1', payin_method: 'apple_pay',
    });

    expect(stripe.createPayinIntent).toHaveBeenCalledWith({
      transferId: expect.any(String), userId: 'u1', amount: 201.99, method: 'apple_pay',
    });
    expect(result.payin_client_secret).toBe('pi_test_123_secret_x');
    expect(result.transfer.status).toBe('pending_payin');
    // Stored payinReference must match Stripe's intent id.
    const stored = Array.from(prisma.transfers.values())[0];
    expect(stored.payinReference).toBe('pi_test_123');
  });

  it('blocks transfer when compliance returns severity=block', async () => {
    const { quote, recipient } = makeFixtures();
    const { service, prisma, stripe } = makeService({
      quote, recipient, compliance: { blocked: true, hits: 1 },
    });

    await expect(
      service.create('u1', { quote_id: 'q1', recipient_id: 'r1', payin_method: 'apple_pay' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(stripe.createPayinIntent).not.toHaveBeenCalled();
    // Transfer row must exist and be marked failed/compliance_blocked.
    const stored = Array.from(prisma.transfers.values())[0];
    expect(stored.status).toBe('failed');
    expect(stored.failureCode).toBe('compliance_blocked');
  });

  it('rejects expired quote with 400', async () => {
    const { quote, recipient } = makeFixtures();
    quote.expiresAt = new Date(Date.now() - 1_000);
    const { service } = makeService({ quote, recipient });
    await expect(
      service.create('u1', { quote_id: 'q1', recipient_id: 'r1', payin_method: 'apple_pay' }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects re-using a quote that already has a transfer (409)', async () => {
    const { quote, recipient } = makeFixtures();
    quote.transfer = { id: 'tx_existing' };
    const { service } = makeService({ quote, recipient });
    await expect(
      service.create('u1', { quote_id: 'q1', recipient_id: 'r1', payin_method: 'apple_pay' }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('rejects recipient corridor mismatch (400)', async () => {
    const { quote, recipient } = makeFixtures();
    recipient.country = 'NG'; // quote was for SN
    const { service } = makeService({ quote, recipient });
    await expect(
      service.create('u1', { quote_id: 'q1', recipient_id: 'r1', payin_method: 'apple_pay' }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('returns 404 when quote not found', async () => {
    const { recipient } = makeFixtures();
    const { service } = makeService({ quote: null, recipient });
    await expect(
      service.create('u1', { quote_id: 'missing', recipient_id: 'r1', payin_method: 'apple_pay' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns 404 when recipient not found', async () => {
    const { quote } = makeFixtures();
    const { service } = makeService({ quote, recipient: null });
    await expect(
      service.create('u1', { quote_id: 'q1', recipient_id: 'missing', payin_method: 'apple_pay' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});

describe('TransfersService.enqueuePayout', () => {
  it('adds a job to the payouts queue with idempotent jobId', async () => {
    const { quote, recipient } = makeFixtures();
    const { service, queue } = makeService({ quote, recipient });
    await service.enqueuePayout('tx_abc');
    expect(queue.add).toHaveBeenCalledWith(
      'create-payout',
      { transferId: 'tx_abc' },
      expect.objectContaining({ jobId: 'payout:tx_abc' }),
    );
  });
});

describe('TransfersService.cancel', () => {
  it('transitions pending_payin → refunded', async () => {
    const { quote, recipient } = makeFixtures();
    const { service, prisma } = makeService({ quote, recipient });
    // Seed a pending transfer
    prisma.transfers.set('tx_seed', {
      id: 'tx_seed', userId: 'u1', quoteId: 'q1', recipientId: 'r1', status: 'pending_payin',
      sendAmount: 200, receiveAmount: 129_880, feeAmount: 1.99, fxRate: 649.4,
      payinProvider: 'stripe', payinReference: 'pi_x', payoutCountry: 'SN',
      failureCode: null, createdAt: new Date(),
    });
    // findFirst is the lookup TransfersService.cancel does; override for this seeded row.
    (prisma.transfer.findFirst as jest.Mock).mockResolvedValueOnce({
      ...prisma.transfers.get('tx_seed'),
      quote: { receiveCurrency: 'XOF' },
    });
    const result = await service.cancel('u1', 'tx_seed');
    expect(result.status).toBe('refunded');
  });

  it('refuses to cancel once payin is received (409)', async () => {
    const { quote, recipient } = makeFixtures();
    const { service, prisma } = makeService({ quote, recipient });
    prisma.transfers.set('tx_seed', {
      id: 'tx_seed', userId: 'u1', quoteId: 'q1', recipientId: 'r1', status: 'payin_received',
      sendAmount: 200, receiveAmount: 129_880, feeAmount: 1.99, fxRate: 649.4,
      payinProvider: 'stripe', payinReference: 'pi_x', payoutCountry: 'SN',
      failureCode: null, createdAt: new Date(),
    });
    (prisma.transfer.findFirst as jest.Mock).mockResolvedValueOnce({
      ...prisma.transfers.get('tx_seed'),
      quote: { receiveCurrency: 'XOF' },
    });
    await expect(service.cancel('u1', 'tx_seed')).rejects.toBeInstanceOf(ConflictException);
  });
});
