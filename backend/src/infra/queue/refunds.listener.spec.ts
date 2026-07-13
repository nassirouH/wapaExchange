import { RefundsListener } from './refunds.listener';

/**
 * The listener subscribes to BullMQ's QueueEvents stream. Rather than spin up
 * a real Redis + Queue here, we intercept the registered `failed` handler and
 * drive it synchronously with crafted job states.
 */

type FailedHandler = (payload: { jobId: string; failedReason: string; prev?: string }) => Promise<void>;

function makeQueue(jobsById: Record<string, { attemptsMade?: number; opts?: { attempts?: number }; data?: { transferId?: string } }>) {
  return {
    opts: { connection: {} },
    getJob: jest.fn(async (jobId: string) => jobsById[jobId] ?? null),
  };
}

function makePrisma(opts: { transfer?: Partial<{ id: string; status: string; payinReference: string | null }> | null } = {}) {
  const transferRow = opts.transfer
    ? { id: 'tx_abc', status: 'payin_received', payinReference: 'pi_abc', ...opts.transfer }
    : null;
  let storedTransfer = transferRow;
  return {
    storedTransfer,
    transfer: {
      findUnique: jest.fn(async () => storedTransfer),
      update: jest.fn(async ({ data }: { data: Record<string, unknown> }) => {
        if (storedTransfer) storedTransfer = { ...storedTransfer, ...data };
        return storedTransfer;
      }),
    },
    transferEvent: { create: jest.fn(async () => ({})) },
    $transaction: jest.fn(async (ops: unknown[]) => ops),
  };
}

function makeStripe(success = true) {
  return {
    refundPayinIntent: jest.fn(async () => {
      if (!success) throw new Error('stripe down');
      return { id: 're_test', status: 'succeeded' };
    }),
  };
}

/**
 * Capture the handler that `events.on('failed', …)` registers, by stubbing
 * QueueEvents on the bullmq module before the listener constructs one.
 */
let capturedHandler: FailedHandler | null = null;

jest.mock('bullmq', () => ({
  QueueEvents: jest.fn().mockImplementation(() => ({
    on: (event: string, handler: FailedHandler) => {
      if (event === 'failed') capturedHandler = handler;
    },
    close: jest.fn(),
  })),
}));

describe('RefundsListener', () => {
  beforeEach(() => {
    capturedHandler = null;
  });

  async function bootstrap(
    jobs: Record<string, { attemptsMade?: number; opts?: { attempts?: number }; data?: { transferId?: string } }>,
    prismaOpts: { transfer?: Partial<{ id: string; status: string; payinReference: string | null }> | null } = { transfer: {} },
    stripeSuccess = true,
  ) {
    const queue = makeQueue(jobs);
    const prisma = makePrisma(prismaOpts);
    const stripe = makeStripe(stripeSuccess);
    const listener = new RefundsListener(queue as never, prisma as never, stripe as never);
    await listener.onModuleInit();
    return { listener, queue, prisma, stripe };
  }

  it('refunds + transitions to refunded after the final retry', async () => {
    const { stripe, prisma } = await bootstrap({
      job_1: { attemptsMade: 5, opts: { attempts: 5 }, data: { transferId: 'tx_abc' } },
    });

    await capturedHandler!({ jobId: 'job_1', failedReason: 'Thunes 500', prev: 'active' });

    expect(stripe.refundPayinIntent).toHaveBeenCalledWith('pi_abc', 'refund:tx_abc');
    expect(prisma.transfer.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ status: 'refunded', failureCode: 'payout_exhausted' }) }),
    );
    expect(prisma.transferEvent.create).toHaveBeenCalled();
  });

  it('does not refund on intermediate failures (still retrying)', async () => {
    const { stripe } = await bootstrap({
      job_1: { attemptsMade: 2, opts: { attempts: 5 }, data: { transferId: 'tx_abc' } },
    });

    await capturedHandler!({ jobId: 'job_1', failedReason: 'transient' });

    expect(stripe.refundPayinIntent).not.toHaveBeenCalled();
  });

  it('is idempotent — already-refunded transfer is skipped', async () => {
    const { stripe, prisma } = await bootstrap(
      { job_1: { attemptsMade: 5, opts: { attempts: 5 }, data: { transferId: 'tx_abc' } } },
      { transfer: { status: 'refunded' } },
    );

    await capturedHandler!({ jobId: 'job_1', failedReason: 'replay' });

    expect(stripe.refundPayinIntent).not.toHaveBeenCalled();
    expect(prisma.transferEvent.create).not.toHaveBeenCalled();
  });

  it('logs but does not throw when Stripe refund fails', async () => {
    const { stripe } = await bootstrap(
      { job_1: { attemptsMade: 5, opts: { attempts: 5 }, data: { transferId: 'tx_abc' } } },
      { transfer: {} },
      false,
    );

    await expect(
      capturedHandler!({ jobId: 'job_1', failedReason: 'final' }),
    ).resolves.toBeUndefined();
    expect(stripe.refundPayinIntent).toHaveBeenCalled();
  });

  it('no-ops when the transfer has no payin_reference', async () => {
    const { stripe } = await bootstrap(
      { job_1: { attemptsMade: 5, opts: { attempts: 5 }, data: { transferId: 'tx_abc' } } },
      { transfer: { payinReference: null } },
    );

    await capturedHandler!({ jobId: 'job_1', failedReason: 'final' });
    expect(stripe.refundPayinIntent).not.toHaveBeenCalled();
  });

  it('no-ops when the job has no transferId in its data', async () => {
    const { stripe } = await bootstrap({
      job_1: { attemptsMade: 5, opts: { attempts: 5 }, data: {} },
    });
    await capturedHandler!({ jobId: 'job_1', failedReason: 'final' });
    expect(stripe.refundPayinIntent).not.toHaveBeenCalled();
  });
});
