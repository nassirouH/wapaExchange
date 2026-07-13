import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { RulesEngine, type RuleContext } from './rules.engine';

@Injectable()
export class ComplianceService {
  private readonly logger = new Logger(ComplianceService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly engine: RulesEngine,
  ) {}

  /**
   * Runs all rules for a transfer and persists any hits.
   * Returns `true` if the transfer should be BLOCKED (severity = block).
   * Called synchronously inside `TransfersService.create`, before pay-in is initiated.
   */
  async evaluateTransfer(ctx: RuleContext): Promise<{ blocked: boolean; hits: number }> {
    const hits = await this.engine.evaluate(ctx);
    if (hits.length === 0) return { blocked: false, hits: 0 };

    await this.prisma.complianceFlag.createMany({
      data: hits.map((h) => ({
        userId: ctx.userId,
        transferId: ctx.transferId,
        ruleId: h.ruleId,
        severity: h.severity,
        reason: h.reason,
        context: h.context,
      })),
    });

    const blocked = hits.some((h) => h.severity === 'block');
    if (blocked) {
      this.logger.warn(
        `Transfer ${ctx.transferId} BLOCKED by compliance rules: ${hits.map((h) => h.ruleId).join(', ')}`,
      );
    }
    return { blocked, hits: hits.length };
  }

  listFlags(opts: { status?: 'open' | 'reviewing'; limit?: number } = {}) {
    return this.prisma.complianceFlag.findMany({
      where: { status: opts.status },
      orderBy: [{ severity: 'desc' }, { createdAt: 'desc' }],
      take: opts.limit ?? 100,
    });
  }

  async reviewFlag(id: string, adminUserId: string, decision: 'cleared' | 'escalated', note: string) {
    return this.prisma.complianceFlag.update({
      where: { id },
      data: {
        status: decision,
        reviewedBy: adminUserId,
        reviewedAt: new Date(),
        reviewerNote: note,
      },
    });
  }
}
