/**
 * One-shot sanctions list seeder. Run with:
 *
 *   npx ts-node scripts/seed-sanctions.ts
 *
 * Downloads OFAC SDN + EU CFSP and writes them into Postgres. Idempotent — safe
 * to re-run.
 */
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { SanctionsSeeder } from '../src/modules/compliance/sanctions.seeder';

async function main() {
  process.env.DISABLE_SANCTIONS_SEEDER = '1'; // skip the cron when running manually
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['error', 'warn', 'log'] });
  const seeder = app.get(SanctionsSeeder);
  const result = await seeder.refresh();
  console.log(`Seeded: OFAC=${result.ofac}, EU=${result.eu}`);
  await app.close();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
