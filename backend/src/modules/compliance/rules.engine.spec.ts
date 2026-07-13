import { RulesEngine, RuleContext } from './rules.engine';
import { SanctionsService, SanctionsMatch } from './sanctions.service';

function ctxOf(overrides: Partial<RuleContext> = {}): RuleContext {
  return {
    userId: 'user_1',
    transferId: 'tx_1',
    sendAmount: 100,
    destinationCountry: 'FR',
    recipientName: 'Jane Smith',
    recipientCountry: 'FR',
    ...overrides,
  };
}

function prismaWith(transferCount = 0, recentTransfers: Array<{ sendAmount: number }> = []) {
  return {
    transfer: {
      count: jest.fn(async () => transferCount),
      findMany: jest.fn(async () => recentTransfers.map((t) => ({ sendAmount: t.sendAmount }))),
    },
  } as never;
}

function sanctionsWith(matches: SanctionsMatch[] = []) {
  const stub = { match: jest.fn(async () => matches) };
  return stub as unknown as SanctionsService;
}

describe('RulesEngine', () => {
  describe('large_amount rule', () => {
    it('does not fire under €1 000', async () => {
      const e = new RulesEngine(prismaWith(), sanctionsWith());
      const hits = await e.evaluate(ctxOf({ sendAmount: 999 }));
      expect(hits.find((h) => h.ruleId === 'rule.large_amount')).toBeUndefined();
    });
    it('fires medium severity at €1 000 ≤ amount < €5 000', async () => {
      const e = new RulesEngine(prismaWith(), sanctionsWith());
      const hits = await e.evaluate(ctxOf({ sendAmount: 1_500 }));
      const hit = hits.find((h) => h.ruleId === 'rule.large_amount');
      expect(hit?.severity).toBe('medium');
    });
    it('fires high severity at amount ≥ €5 000', async () => {
      const e = new RulesEngine(prismaWith(), sanctionsWith());
      const hits = await e.evaluate(ctxOf({ sendAmount: 5_000 }));
      const hit = hits.find((h) => h.ruleId === 'rule.large_amount');
      expect(hit?.severity).toBe('high');
    });
  });

  describe('velocity_24h rule', () => {
    it('does not fire under 4 transfers in 24h', async () => {
      const e = new RulesEngine(prismaWith(3), sanctionsWith());
      const hits = await e.evaluate(ctxOf());
      expect(hits.find((h) => h.ruleId === 'rule.velocity_24h')).toBeUndefined();
    });
    it('fires at 4+ transfers in 24h', async () => {
      const e = new RulesEngine(prismaWith(4), sanctionsWith());
      const hits = await e.evaluate(ctxOf());
      const hit = hits.find((h) => h.ruleId === 'rule.velocity_24h');
      expect(hit?.severity).toBe('medium');
    });
  });

  describe('high_risk_country rule', () => {
    it('fires for FATF-grey countries (e.g. SN)', async () => {
      const e = new RulesEngine(prismaWith(), sanctionsWith());
      const hits = await e.evaluate(ctxOf({ destinationCountry: 'SN' }));
      expect(hits.find((h) => h.ruleId === 'rule.high_risk_country')).toBeDefined();
    });
    it('does not fire for non-listed countries (e.g. FR)', async () => {
      const e = new RulesEngine(prismaWith(), sanctionsWith());
      const hits = await e.evaluate(ctxOf({ destinationCountry: 'FR' }));
      expect(hits.find((h) => h.ruleId === 'rule.high_risk_country')).toBeUndefined();
    });
  });

  describe('sanctions_hit rule', () => {
    it('does not fire with no matches', async () => {
      const e = new RulesEngine(prismaWith(), sanctionsWith([]));
      const hits = await e.evaluate(ctxOf());
      expect(hits.find((h) => h.ruleId === 'rule.sanctions_hit')).toBeUndefined();
    });
    it('fires HIGH at score 0.85–0.94', async () => {
      const e = new RulesEngine(
        prismaWith(),
        sanctionsWith([{ id: 's1', source: 'ofac', fullName: 'Jane Smyth', country: null, score: 0.9 }]),
      );
      const hits = await e.evaluate(ctxOf());
      const hit = hits.find((h) => h.ruleId === 'rule.sanctions_hit');
      expect(hit?.severity).toBe('high');
    });
    it('fires BLOCK at score ≥ 0.95', async () => {
      const e = new RulesEngine(
        prismaWith(),
        sanctionsWith([{ id: 's1', source: 'ofac', fullName: 'Jane Smith', country: null, score: 0.97 }]),
      );
      const hits = await e.evaluate(ctxOf());
      const hit = hits.find((h) => h.ruleId === 'rule.sanctions_hit');
      expect(hit?.severity).toBe('block');
    });
  });

  describe('structuring rule', () => {
    it('fires when 2+ transfers fall in [€900, €1 000) within 7 days', async () => {
      const e = new RulesEngine(
        prismaWith(0, [{ sendAmount: 950 }, { sendAmount: 980 }]),
        sanctionsWith(),
      );
      const hits = await e.evaluate(ctxOf());
      const hit = hits.find((h) => h.ruleId === 'rule.structuring');
      expect(hit?.severity).toBe('high');
    });
    it('does not fire with only 1 just-below transfer', async () => {
      const e = new RulesEngine(
        prismaWith(0, [{ sendAmount: 950 }, { sendAmount: 200 }]),
        sanctionsWith(),
      );
      const hits = await e.evaluate(ctxOf());
      expect(hits.find((h) => h.ruleId === 'rule.structuring')).toBeUndefined();
    });
  });

  it('returns multiple hits when several rules fire together', async () => {
    const e = new RulesEngine(
      prismaWith(5, [{ sendAmount: 950 }, { sendAmount: 970 }]),
      sanctionsWith([{ id: 's1', source: 'ofac', fullName: 'Jane Smith', country: null, score: 0.99 }]),
    );
    const hits = await e.evaluate(ctxOf({ sendAmount: 6_000, destinationCountry: 'SN' }));
    // Expect: large_amount + velocity + high_risk_country + sanctions + structuring
    expect(hits.length).toBeGreaterThanOrEqual(5);
    expect(hits.some((h) => h.severity === 'block')).toBe(true);
  });
});
