# wapaExchange Backend

NestJS 10 + Prisma + PostgreSQL + Redis. Implements the API documented at `../wapaExchange/Docs/04_APIStructure.md`.

## Quick start

```bash
cp .env.example .env                # fill secrets
docker compose up -d                # postgres + redis
npm install
npx prisma generate
npx prisma migrate dev --name init
npm run start:dev
```

API is at `http://localhost:3000/v1`, Swagger at `http://localhost:3000/v1/docs`.

## Modules

| Module | What it does |
|---|---|
| `auth` | Email + password, JWT access (15 min) + rotating refresh (30 d) hashed in DB |
| `users` | `/me` profile read / patch / soft delete |
| `kyc` | Creates Sumsub applicants, returns SDK token, handles webhook in `webhooks` |
| `recipients` | CRUD + favorite toggle, scoped by `userId` |
| `quotes` | FX + fee calculation. Mock rates inline — wire to OpenExchangeRates / Wise feed |
| `transfers` | Creates a transfer from a valid quote + recipient, returns pay-in client secret |
| `webhooks` | Stripe (pay-in), Thunes (pay-out), Sumsub (KYC). HMAC-verified in prod |
| `notifications` | APNs device registration + inbox |

## Money flow contract

The backend NEVER holds customer funds. The flow is:

1. App calls `POST /v1/transfers` → backend creates a `Transfer` row + a Stripe PaymentIntent with `metadata.transfer_id`.
2. App completes pay-in client-side (Apple Pay / SEPA via Stripe).
3. Stripe webhook → `payment_intent.succeeded` → transfer status `payin_received`.
4. Backend enqueues a payout job → calls Thunes / MFS / Flutterwave.
5. Partner webhook → `payout_complete` → push notification sent.
6. Pay-in PSP forwards principal → payout PSP. Our company account only receives the fee + FX margin via settlement run.

Implement steps 4–5 by adding a BullMQ worker that consumes `payouts` queue after `payin_received`.

## Production checklist

- [ ] Replace mock FX rates with a real feed + Redis cache (1-min TTL).
- [ ] Switch webhook signature verification to use the raw request body (`bodyParser: false` + Stripe SDK).
- [ ] Add column-level encryption (pgcrypto) for `users.fullName`, DOB, recipient bank fields.
- [ ] Add IP / device fingerprint logging into an append-only `audit_events` table.
- [ ] Rate-limit `/auth/login` (10/min/IP) on top of the global throttler.
- [ ] Wire the payout queue (`@nestjs/bull` or `bullmq`) and a worker process.
- [ ] Front everything with a licensed PI/EMI partner contract.
