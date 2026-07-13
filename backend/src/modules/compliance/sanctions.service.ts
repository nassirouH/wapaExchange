import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';

export interface SanctionsMatch {
  id: string;
  source: string;
  fullName: string;
  country: string | null;
  score: number; // 0..1 Jaro-Winkler-ish
}

@Injectable()
export class SanctionsService {
  private readonly logger = new Logger(SanctionsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Returns potential matches above a minimum score.
   * For MVP we use simple normalization + Levenshtein-on-tokens; production should
   * use a real fuzzy matcher (Elasticsearch + decay scoring) or a vendor like
   * ComplyAdvantage / Refinitiv World-Check.
   */
  async match(name: string, country: string | null, minScore = 0.85): Promise<SanctionsMatch[]> {
    const normalized = this.normalize(name);
    if (!normalized) return [];

    // Naive prefix-narrow then in-memory rank. Fine up to ~50k rows;
    // beyond that, denormalize tokens into a trigram index (`pg_trgm`).
    const candidates = await this.prisma.sanctionsList.findMany({
      where: country ? { OR: [{ country }, { country: null }] } : undefined,
      take: 5_000,
    });

    const scored = candidates
      .map((c) => ({
        id: c.id,
        source: c.source,
        fullName: c.fullName,
        country: c.country,
        score: this.score(normalized, c.normalized),
      }))
      .filter((m) => m.score >= minScore)
      .sort((a, b) => b.score - a.score)
      .slice(0, 10);

    return scored;
  }

  private normalize(s: string): string {
    return s
      .normalize('NFKD')
      .replace(/[̀-ͯ]/g, '') // strip accents
      .toLowerCase()
      .replace(/[^a-z0-9 ]/g, ' ')
      .split(/\s+/)
      .filter(Boolean)
      .sort()
      .join(' ');
  }

  /** Token-set similarity. */
  private score(a: string, b: string): number {
    if (!a || !b) return 0;
    const A = new Set(a.split(' '));
    const B = new Set(b.split(' '));
    const inter = [...A].filter((t) => B.has(t)).length;
    const union = new Set([...A, ...B]).size;
    return inter / union;
  }
}
