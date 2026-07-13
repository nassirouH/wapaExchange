import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { SanctionsService } from './sanctions.service';

export interface RuleContext {
  userId: string;
  transferId: string;
  sendAmount: number;
  destinationCountry: string;
  recipientName: string;
  recipientCountry: string;
}

export interface RuleHit {
  ruleId: string;
  severity: 'low' | 'medium' | 'high' | 'block';
  reason: string;
  context: Record<string, unknown>;
}

/**
 * Adding a new rule:
 *   1. Implement `Rule.evaluate(ctx)` returning `RuleHit | null`.
 *   2. Register it in `RulesEngine.rules` below.
 *
 * Rules must be cheap (sub-100 ms) and side-effect free. Persistence is handled
 * by `ComplianceService.evaluateTransfer`.
 */
interface Rule {
  id: string;
  evaluate(ctx: RuleContext): Promise<RuleHit | null>;
}

const HIGH_RISK_COUNTRIES = new Set<string>([
  // FATF grey list + jurisdictions with elevated AML risk (sample — keep this in sync
  // with the official list at https://www.fatf-gafi.org/en/countries/black-and-grey-lists.html)
  'AF', 'BB', 'BF', 'CM', 'CD', 'GI', 'HT', 'JM', 'ML', 'MZ',
  'MM', 'NG', 'PA', 'PH', 'SN', 'SS', 'SY', 'TR', 'UG', 'AE',
  'VU', 'YE',
]);

@Injectable()
export class RulesEngine {
  private readonly rules: Rule[];

  constructor(
    private readonly prisma: PrismaService,
    private readonly sanctions: SanctionsService,
  ) {
    this.rules = [
      this.largeAmountRule(),
      this.velocityRule(),
      this.highRiskCountryRule(),
      this.sanctionsHitRule(),
      this.structuringRule(),
    ];
  }

  async evaluate(ctx: RuleContext): Promise<RuleHit[]> {
    const hits = await Promise.all(this.rules.map((r) => r.evaluate(ctx).catch(() => null)));
    return hits.filter((h): h is RuleHit => h !== null);
  }

  // -------- individual rules --------

  private largeAmountRule(): Rule {
    return {
      id: 'rule.large_amount',
      evaluate: async (ctx) => {
        if (ctx.sendAmount >= 5_000) {
          return {
            ruleId: 'rule.large_amount',
            severity: 'high',
            reason: 'Transfer ≥ €5 000 — enhanced due diligence required.',
            context: { sendAmount: ctx.sendAmount },
          };
        }
        if (ctx.sendAmount >= 1_000) {
          return {
            ruleId: 'rule.large_amount',
            severity: 'medium',
            reason: 'Transfer ≥ €1 000 — review for source of funds.',
            context: { sendAmount: ctx.sendAmount },
          };
        }
        return null;
      },
    };
  }

  /** 4+ transfers in a 24h window from the same user. */
  private velocityRule(): Rule {
    return {
      id: 'rule.velocity_24h',
      evaluate: async (ctx) => {
        const since = new Date(Date.now() - 24 * 3600 * 1000);
        const count = await this.prisma.transfer.count({
          where: { userId: ctx.userId, createdAt: { gte: since } },
        });
        if (count >= 4) {
          return {
            ruleId: 'rule.velocity_24h',
            severity: 'medium',
            reason: `${count} transfers in the last 24 hours.`,
            context: { count, windowHours: 24 },
          };
        }
        return null;
      },
    };
  }

  private highRiskCountryRule(): Rule {
    return {
      id: 'rule.high_risk_country',
      evaluate: async (ctx) => {
        if (HIGH_RISK_COUNTRIES.has(ctx.destinationCountry)) {
          return {
            ruleId: 'rule.high_risk_country',
            severity: 'medium',
            reason: `Destination ${ctx.destinationCountry} on enhanced-monitoring list.`,
            context: { country: ctx.destinationCountry },
          };
        }
        return null;
      },
    };
  }

  private sanctionsHitRule(): Rule {
    return {
      id: 'rule.sanctions_hit',
      evaluate: async (ctx) => {
        const matches = await this.sanctions.match(ctx.recipientName, ctx.recipientCountry);
        if (matches.length === 0) return null;
        const top = matches[0];
        return {
          ruleId: 'rule.sanctions_hit',
          severity: top.score >= 0.95 ? 'block' : 'high',
          reason: `Potential sanctions list match (${top.source}, score ${top.score.toFixed(2)}).`,
          context: { matches: matches.slice(0, 5) },
        };
      },
    };
  }

  /** Multiple just-below-threshold transfers (smurfing/structuring). */
  private structuringRule(): Rule {
    return {
      id: 'rule.structuring',
      evaluate: async (ctx) => {
        const since = new Date(Date.now() - 7 * 86_400 * 1000);
        const recent = await this.prisma.transfer.findMany({
          where: { userId: ctx.userId, createdAt: { gte: since } },
          select: { sendAmount: true },
        });
        const justBelow = recent.filter((r) => {
          const a = Number(r.sendAmount);
          return a >= 900 && a < 1_000;
        });
        if (justBelow.length >= 2) {
          return {
            ruleId: 'rule.structuring',
            severity: 'high',
            reason: 'Multiple transfers just below €1 000 reporting threshold.',
            context: { hits: justBelow.length, windowDays: 7 },
          };
        }
        return null;
      },
    };
  }
}
