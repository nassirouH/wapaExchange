# wapaExchange — EMI / PI Partner Outreach Pack

> One-pager for first contact with Lemonway, MangoPay, Modulr, Currencycloud,
> NIUM, Treezor, Sopra-Banking and similar. Drop it into the body of an email
> or attach as PDF. Personalise the **{{…}}** placeholders.

---

## Who we are

**wapaExchange** — a mobile remittance app from Europe to Africa and Asia, built by **Nassirou Hassan** ({{LinkedIn URL}}). iOS launches first; Android follows. Company: **{{Company SAS}}**, registered in **{{France, SIREN xxx}}**.

## What we want

A **regulated banking / EMI partner** under whose licence we operate as a **distribution agent** (PSD2 art. 19 / art. 34). We do not custody funds. You handle the regulated flow; we own the user experience, marketing and acquisition.

## What we bring

| | |
|---|---|
| **Wedge corridor** | France → Senegal + Côte d'Ivoire (Orange Money, Wave, MTN) |
| **Target users** | Senegalese / Ivorian diaspora in Paris, Lyon, Marseille (~500 k people) |
| **Average ticket** | €100–500 |
| **Year-1 volume goal** | €6–12 M GMV |
| **Year-1 transactions** | 25 k–60 k |
| **Tech** | iOS app live, NestJS backend, Sumsub KYC integrated, Stripe pay-in integrated, Thunes payout integrated — **all sandbox**, ready to switch to production on contract signature |

## What we ask for

1. **Agent registration** under your licence in France (BCE for Belgium / ACPR for France equivalents).
2. **Segregated client-money account(s)** that receive pay-in and forward to payout PSPs. We never touch principal.
3. **API access** to:
   - create / read sub-ledgers per transfer
   - register beneficiaries and trigger SEPA pay-ins
   - receive webhooks on every state transition
4. **Compliance support**: AML policy template, sanctions screening (we have ours, want yours overlayed), suspicious-transaction-report (STR) workflow with your MLRO.
5. **Pricing**: tiered platform fee with **volume floor ≤ €1 k/mo for first 6 months**, then sliding scale tied to GMV.

## What we are NOT asking

- Lending, card issuance, savings products — out of scope for year 1.
- Crypto rails.
- Bringing customer funds onto our balance sheet at any point.

## Compliance posture (today)

- Sumsub KYC integrated; thresholds: passport + selfie + liveness; rejection workflow handled in-app.
- Transaction monitoring engine in production (rules engine with: large-amount, velocity, structuring, sanctions hit, high-risk country); flags reviewed daily.
- Sanctions lists: OFAC SDN, EU CFSP, UK HMT, UN — refreshed nightly.
- 7-year record retention with column-level encryption on PII.
- AML officer engaged: **{{name, certification}}** — currently fractional, becoming full-time at €5 M GMV.

## Timeline ask

| Week | Milestone |
|---|---|
| 0 | This email |
| 1 | 30-min intro call — your product & legal teams |
| 2 | NDA + term sheet |
| 4 | Master Services Agreement signed |
| 5 | Sandbox API access |
| 8 | Production agent registration filed with regulator |
| 12 | Soft launch — closed beta of 100 users |
| 16 | Public launch, App Store |

## What we don't yet have

- A signed MSA with a regulated partner — that's why we're writing.
- Revenue. We are pre-launch.
- Outside funding. Bootstrapped to date; raising pre-seed once we have signed term sheet.

## Why now

The EU-Africa remittance corridor is **€31 bn/year**, dominated by Western Union and MoneyGram with average all-in cost of **6.2%** (World Bank Q4 2025). LemFi has shown the unit economics are there if the cost stack is below 3%. We can be at **1.5% effective cost** because we ride your licence and direct payout-aggregator rails — no retail branches, no card networks, no FX hedging book.

## Contact

**{{Founder name}}** — {{email}} — {{phone}}
GitHub demo: {{repo URL or TestFlight link}}
Pitch deck: {{Drive / DocSend link}}

---

> *Send order:* try Lemonway and MangoPay first (Paris-based, French + remittance experience). NIUM second (best for multi-corridor scale, harder to onboard small). Treezor + Modulr if both decline. Reply rates on cold outbound are 10–15%; expect 5–7 follow-ups per partner.
