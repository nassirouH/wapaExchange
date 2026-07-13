# wapaExchange — Roadmap, Revenue Model, Cost Estimates

## 1. 12-Month Launch Roadmap

| Month | Milestone | Key dependency |
|---|---|---|
| 0–1 | Incorporate (SAS in France), sign NDA + term sheet with licensed PI partner (e.g., Lemonway / MangoPay) | Founder time + legal advisor |
| 1–2 | Build iOS MVP (this codebase), NestJS backend, Sumsub KYC sandbox, Stripe pay-in test | Solo founder |
| 2–3 | Integrate Thunes or MFS Africa sandbox for Senegal + Côte d'Ivoire payouts | Partner contract |
| 3 | Closed beta — 30 invited diaspora users, real money, capped at €200/txn | Live partner agreement |
| 4 | TestFlight public beta, push to 500 waitlist users | App Store review |
| 5 | Public App Store launch (FR + DE) | App Store approval |
| 6 | Add UK corridor + Nigeria (NGN) payout via Flutterwave | UK PI partner |
| 7–8 | Android (Phase 2) | — |
| 9 | Reach 5k MAU, raise pre-seed (~€500k) | Traction |
| 10–12 | Apply for own SPI license, hire 1 compliance officer + 1 backend engineer | Capital |

## 2. Revenue Model

For an average €200 transfer to Senegal (XOF):

| Revenue source | Per transfer | Notes |
|---|---|---|
| FX spread (1.0%) | €2.00 | We sell EUR→XOF at 1% above mid-rate |
| Fixed fee | €1.99 | Tiered: €0.99 <€100, €1.99 ≤€500, €3.99 ≤€2,000 |
| Express upgrade (opt-in) | +€2.00 | "Within 1 hour" via premium partner |
| **Avg gross per txn** | **€4.50–6.00** | |

Cost stack per €200 transfer:
| Cost | Per transfer |
|---|---|
| Stripe SEPA pay-in (0.8% + €0.25) | €1.85 |
| Payout partner fee | €1.00–2.00 |
| KYC (amortised, first txn only) | €0.50 |
| **Net per txn** | **€1.00–2.50** |

At 2,000 transfers/month (month 6 target): **€2k–5k MRR**.
At 20,000 transfers/month (month 12 target): **€20k–50k MRR**.

### Phase 2+ revenue streams (not in MVP)
- **Premium subscription** (€4.99/mo) — fee-free transfers under €500, priority support.
- **Business accounts** — SMEs, higher volume, custom pricing.
- **Card issuance** (via BaaS) — interchange revenue (Phase 3+).

## 3. MVP Cost Estimates (one-time + 6 months)

| Item | One-time | Monthly | 6-mo total |
|---|---|---|---|
| Company incorporation (France SAS) | €1,500 | — | €1,500 |
| Legal / compliance advisor (fractional) | — | €1,500 | €9,000 |
| Apple Developer account | €99 | — | €99 |
| Domain + email (Google Workspace) | — | €15 | €90 |
| AWS (ECS Fargate small + RDS t4g.small + Redis + S3) | — | €180 | €1,080 |
| Sumsub KYC sandbox → prod | — | €0 → €300 | €900 |
| Stripe (pass-through, no fixed) | — | €0 | €0 |
| Thunes / MFS sandbox | — | €0 | €0 |
| Sentry + Datadog (free tiers) | — | €0 | €0 |
| Intercom starter | — | €74 | €444 |
| Insurance (E&O / cyber) | — | €200 | €1,200 |
| App Store / marketing budget | — | €500 | €3,000 |
| **Subtotal** | **€1,599** | **€2,769/mo** | **€17,313** |
| Buffer (30%) | | | €5,200 |
| **Total MVP capital needed** | | | **~€22,500** |

Does **not** include founder salary. Hireable assets like a part-time backend engineer (~€3k/mo) would push this to ~€40k.

## 4. Future Scaling Strategy (summary)

- **Year 1**: Operate under licensed PI partner. Focus on 3 corridors, single region (eu-west-3).
- **Year 2**: Apply for own SPI in France (€50k regulatory capital). Add UK, Spain origins. Add 5 more African corridors. Switch from Fargate to EKS + horizontal sharding of `transfers` table by user_id hash.
- **Year 3**: Acquire EMI passporting across EU. Launch Asia corridor (Philippines, Bangladesh, India). Migrate ledger to a dedicated double-entry service (use `tigerbeetle` or Postgres ledger pattern).
- **Always**: Never custody end-user balances. Even with own license, run as flow-through orchestrator until volume justifies full wallet product.
