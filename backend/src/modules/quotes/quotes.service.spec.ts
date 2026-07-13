import { BadRequestException } from '@nestjs/common';
import { QuotesService } from './quotes.service';

/**
 * Minimal prisma test double — only stubs what QuotesService actually calls.
 * Captures `create` calls for assertion.
 */
function makePrismaMock() {
  const created: unknown[] = [];
  return {
    created,
    quote: {
      create: jest.fn(async ({ data }: { data: Record<string, unknown> }) => {
        const row = { id: 'quote_test_id', ...data };
        created.push(row);
        return row;
      }),
    },
  };
}

describe('QuotesService', () => {
  let service: QuotesService;
  let prisma: ReturnType<typeof makePrismaMock>;

  beforeEach(() => {
    prisma = makePrismaMock();
    service = new QuotesService(prisma as never);
  });

  it('calculates the receive amount with the 1% FX margin', async () => {
    const result = await service.create('user_1', {
      send_currency: 'EUR',
      send_amount: 200,
      destination_country: 'SN',
      payout_method: 'mobile_money',
    });

    // 200 EUR × 655.96 × (1 - 0.01) ≈ 129 880.08 XOF
    expect(result.receive_currency).toBe('XOF');
    expect(Number(result.receive_amount)).toBeCloseTo(129_880.08, 2);
    expect(Number(result.fx_rate)).toBeCloseTo(649.40, 2);
  });

  it('applies tiered fees: €0.99 under €100, €1.99 up to €500, €3.99 above', async () => {
    const small = await service.create('user_1', {
      send_currency: 'EUR', send_amount: 50, destination_country: 'SN', payout_method: 'mobile_money',
    });
    const medium = await service.create('user_1', {
      send_currency: 'EUR', send_amount: 200, destination_country: 'SN', payout_method: 'mobile_money',
    });
    const large = await service.create('user_1', {
      send_currency: 'EUR', send_amount: 1_000, destination_country: 'NG', payout_method: 'bank_transfer',
    });

    expect(Number(small.fee_amount)).toBe(0.99);
    expect(Number(medium.fee_amount)).toBe(1.99);
    expect(Number(large.fee_amount)).toBe(3.99);
  });

  it('sets a 5-minute TTL on the quote', async () => {
    const before = Date.now();
    const result = await service.create('user_1', {
      send_currency: 'EUR', send_amount: 100, destination_country: 'SN', payout_method: 'mobile_money',
    });
    const ttl = new Date(result.expires_at).getTime() - before;
    expect(ttl).toBeGreaterThanOrEqual(5 * 60 * 1000 - 100);
    expect(ttl).toBeLessThanOrEqual(5 * 60 * 1000 + 100);
  });

  it('rejects unsupported destination countries', async () => {
    await expect(
      service.create('user_1', {
        send_currency: 'EUR', send_amount: 100, destination_country: 'ZZ', payout_method: 'mobile_money',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('persists the quote with all derived fields', async () => {
    await service.create('user_1', {
      send_currency: 'EUR', send_amount: 200, destination_country: 'SN', payout_method: 'mobile_money',
    });
    expect(prisma.quote.create).toHaveBeenCalledTimes(1);
    const saved = prisma.created[0] as Record<string, unknown>;
    expect(saved).toMatchObject({
      userId: 'user_1',
      sendCurrency: 'EUR',
      receiveCurrency: 'XOF',
      destinationCountry: 'SN',
      payoutMethod: 'mobile_money',
      fxMarginBps: 100,
    });
  });
});
