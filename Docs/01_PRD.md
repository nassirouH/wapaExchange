# wapaExchange — Product Requirements Document (PRD)

## 1. Vision
wapaExchange is a mobile-first remittance technology layer that lets Europe-based senders move money to Africa and Asia through licensed third-party payment partners. The company never holds customer funds, never operates as a bank, and never appears on the regulated rails — it only orchestrates flows between licensed providers and earns a margin on FX spread + per-transfer fees.

## 2. Problem
- Europe→Africa remittances are dominated by expensive incumbents (4–7% effective cost) and fragmented mobile money silos.
- Solo founders cannot afford an EMI/PI license (≥€350k regulatory capital + 12–18 months).
- Existing BaaS providers (Modulr, Currencycloud, Thunes, NIUM) and remittance APIs (LemFi-as-a-service, Transfast, Flutterwave Remit, MFS Africa) make a non-licensed orchestration model viable.

## 3. Target Users
| Segment | Description | Volume |
|---|---|---|
| Primary | African/Asian diaspora in EU sending family support | €100–500 per transfer, 2–4× / month |
| Secondary | SME importers paying small suppliers in Africa | €500–5,000 per transfer, 1–2× / month |

## 4. MVP Goals (90-day target)
- 500 verified senders.
- 1 corridor live: **France/Germany → Senegal + Côte d'Ivoire** (Orange Money, MTN, Wave + local bank payouts).
- 1 licensed regulated partner contracted (e.g., MangoPay, Lemonway, Stripe Treasury via EMI, or LemFi B2B API).
- 1 payout aggregator integrated (Thunes or MFS Africa or Flutterwave).
- Sub-60s quote→confirm UX, <24h payout SLA on mobile money.

## 5. Non-Goals (Out of MVP)
- Holding balances / wallets that the company custodies directly.
- Cards issued by us.
- Crypto rails.
- Business accounts, subscriptions, premium tiers (Phase 2+).
- Admin web dashboard (Phase 2 — server-side admin via Retool/Forest until then).
- Android app (Phase 2).

## 6. MVP Feature List (Phase 1)
1. **Auth** — Email + password, social (Apple, Google), JWT session, biometric unlock (Face ID).
2. **KYC onboarding** — Selfie + ID via 3rd-party SDK (Sumsub / Onfido / Veriff sandbox).
3. **Sender profile** — Name, address, source of funds, occupation.
4. **Recipient management** — Add, edit, favorite, recent.
5. **Quote calculator** — FX rate + fees displayed before confirmation.
6. **Transfer flow** — Choose recipient → pick payout method (mobile money / bank) → confirm → pay-in (SEPA / card via Stripe).
7. **Transfer tracking** — States: `quoted → paid-in → forwarded → paid-out → complete`.
8. **Transaction history** — Filterable list, detail screen with receipt.
9. **Push notifications** — Status updates via APNs.
10. **Customer support chat** — Intercom or Crisp SDK embed.

## 7. Success Metrics
| Metric | Target by month 3 |
|---|---|
| Verified users | 500 |
| First transfers | 250 |
| Repeat rate (≥2 transfers) | 35% |
| Avg. revenue per transfer | €4–7 |
| KYC pass rate | ≥75% |
| Quote → paid-in conversion | ≥40% |

## 8. Constraints
- **Regulatory:** Must operate as agent/partner of a licensed EMI or PI under PSD2. No money handling.
- **Capital:** <€50k for MVP launch (excluding founder time).
- **Team:** Solo founder + 1 part-time compliance advisor for first 6 months.
- **Tech:** iOS-first (SwiftUI), NestJS backend, single AWS region (eu-west-3 Paris) for data residency.

## 9. Assumptions / Open Questions
- Need signed agreement with a licensed PI/EMI before going live. Until then, app runs in sandbox mode.
- KYC vendor pricing: ~€1.50–3.00 per verification.
- Payout aggregator FX margin: 0.5–1.5% — we add 0.5–1.5% on top.
