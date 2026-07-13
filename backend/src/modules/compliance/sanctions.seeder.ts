import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../infra/prisma/prisma.service';

interface SanctionsEntry {
  source: 'ofac' | 'eu-cfsp' | 'uk-hmt' | 'un';
  fullName: string;
  dateOfBirth?: Date | null;
  country?: string | null;
  rawPayload: Record<string, unknown>;
}

/**
 * Downloads OFAC SDN + EU CFSP consolidated sanctions lists nightly and upserts
 * them into the `sanctions_list` table. The `normalized` column is what
 * SanctionsService.match() searches against — see normalize() below.
 *
 * Production hardening:
 *   - Add UK HMT (https://docs.fcdo.gov.uk/docs/UK-Sanctions-List.html) and UN.
 *   - Cache the previous fetch ETag to skip unchanged days.
 *   - Hold an MD5 of each row's raw payload; only upsert when it changes.
 */
@Injectable()
export class SanctionsSeeder {
  private readonly logger = new Logger(SanctionsSeeder.name);
  private readonly OFAC_SDN_URL = 'https://www.treasury.gov/ofac/downloads/sdn.csv';
  private readonly EU_CFSP_URL =
    'https://webgate.ec.europa.eu/europeaid/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content';

  constructor(private readonly prisma: PrismaService) {}

  /** Runs every day at 03:00 UTC. Off-hours for most EU operations. */
  @Cron('0 3 * * *', { timeZone: 'UTC' })
  async dailyRefresh() {
    if (process.env.DISABLE_SANCTIONS_SEEDER === '1') {
      this.logger.log('Sanctions seeder disabled by env flag.');
      return;
    }
    await this.refresh();
  }

  /** Public entry point — also callable via a CLI script for first-run seeding. */
  async refresh(): Promise<{ ofac: number; eu: number }> {
    const start = Date.now();
    const [ofac, eu] = await Promise.allSettled([this.fetchOfacSdn(), this.fetchEuCfsp()]);

    const ofacEntries = ofac.status === 'fulfilled' ? ofac.value : [];
    const euEntries = eu.status === 'fulfilled' ? eu.value : [];

    if (ofac.status === 'rejected') this.logger.error('OFAC SDN fetch failed', ofac.reason);
    if (eu.status === 'rejected') this.logger.error('EU CFSP fetch failed', eu.reason);

    const all = [...ofacEntries, ...euEntries];
    await this.upsertAll(all);

    this.logger.log({
      msg: 'Sanctions refresh complete',
      ofac: ofacEntries.length,
      eu: euEntries.length,
      duration_ms: Date.now() - start,
    });
    return { ofac: ofacEntries.length, eu: euEntries.length };
  }

  private async fetchOfacSdn(): Promise<SanctionsEntry[]> {
    const res = await fetch(this.OFAC_SDN_URL);
    if (!res.ok) throw new Error(`OFAC SDN ${res.status}`);
    const text = await res.text();
    // SDN.csv schema:  ent_num,SDN_Name,SDN_Type,Program,Title,Call_Sign,Vess_type,Tonnage,GRT,Vess_flag,Vess_owner,Remarks
    return parseCsv(text)
      .filter((cols) => cols[2] === 'individual' || cols[2] === '"individual"')
      .map((cols) => ({
        source: 'ofac' as const,
        fullName: stripQuotes(cols[1] ?? ''),
        country: null,
        rawPayload: { ent_num: cols[0], program: stripQuotes(cols[3] ?? '') },
      }))
      .filter((e) => e.fullName.length > 0);
  }

  private async fetchEuCfsp(): Promise<SanctionsEntry[]> {
    // The EU list is XML; we hand-parse a tiny subset (sufficient for an MVP that
    // re-ranks server-side anyway). For production swap in `fast-xml-parser`.
    const res = await fetch(this.EU_CFSP_URL);
    if (!res.ok) throw new Error(`EU CFSP ${res.status}`);
    const text = await res.text();
    const matches = [...text.matchAll(/<wholeName>([^<]+)<\/wholeName>[\s\S]*?(?:<countryDescription>([^<]+)<\/countryDescription>)?/g)];
    return matches.map((m) => ({
      source: 'eu-cfsp' as const,
      fullName: decodeXmlEntities(m[1]),
      country: m[2] ? decodeXmlEntities(m[2]) : null,
      rawPayload: {},
    }));
  }

  private async upsertAll(entries: SanctionsEntry[]) {
    // Bulk upsert: collapse by (source, fullName), 1 transaction every 500 rows.
    const dedup = new Map<string, SanctionsEntry>();
    for (const e of entries) {
      dedup.set(`${e.source}|${e.fullName.toLowerCase()}`, e);
    }
    const rows = [...dedup.values()].map((e) => ({
      source: e.source,
      fullName: e.fullName,
      normalized: normalize(e.fullName),
      country: e.country ?? null,
      rawPayload: e.rawPayload as object,
    }));

    const CHUNK = 500;
    for (let i = 0; i < rows.length; i += CHUNK) {
      const chunk = rows.slice(i, i + CHUNK);
      // No native multi-upsert; use createMany with skipDuplicates + a separate
      // updateMany for changed names. For MVP we just createMany skip-dup.
      await this.prisma.sanctionsList.createMany({ data: chunk, skipDuplicates: true });
    }
  }
}

function parseCsv(text: string): string[][] {
  return text
    .split('\n')
    .filter((l) => l.trim().length)
    .map((l) => l.split(','));
}

function stripQuotes(s: string): string {
  return s.replace(/^"+|"+$/g, '').trim();
}

function decodeXmlEntities(s: string): string {
  return s
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'");
}

function normalize(s: string): string {
  return s
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9 ]/g, ' ')
    .split(/\s+/)
    .filter(Boolean)
    .sort()
    .join(' ');
}
