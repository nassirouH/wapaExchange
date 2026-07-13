# wapaExchange — System Architecture

## 1. High-Level Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                          iOS App (SwiftUI)                         │
│  MVVM • async/await • URLSession • Keychain • APNs • LocalAuth     │
└──────────────────────────────┬─────────────────────────────────────┘
                               │ HTTPS / JWT
                               ▼
┌────────────────────────────────────────────────────────────────────┐
│                  Backend API (NestJS, Node 20)                     │
│  REST • JWT • Bull queues • Pino logs • OpenAPI / Swagger          │
│                                                                    │
│  Modules:  auth · users · kyc · recipients · quotes · transfers    │
│            payins · payouts · webhooks · notifications · support   │
└──┬────────────────┬──────────────┬──────────────┬─────────────────┘
   │                │              │              │
   ▼                ▼              ▼              ▼
┌───────────┐  ┌──────────┐  ┌─────────────┐  ┌──────────────┐
│PostgreSQL │  │  Redis   │  │  S3 (KYC    │  │ AWS Secrets  │
│ (RDS,     │  │ (sessions│  │  docs,      │  │   Manager    │
│  eu-west-3│  │  + Bull) │  │  receipts)  │  │              │
└───────────┘  └──────────┘  └─────────────┘  └──────────────┘

   External integrations (all licensed third parties):
   ┌──────────────┬──────────────┬──────────────┬──────────────┐
   │  Stripe /    │  Sumsub /    │  Thunes /    │  Twilio /    │
   │  TrueLayer   │  Onfido      │  MFS Africa /│  Sendgrid /  │
   │  (pay-in EU) │  (KYC/AML)   │  Flutterwave │  Intercom    │
   │              │              │  (pay-out)   │              │
   └──────────────┴──────────────┴──────────────┴──────────────┘
```

## 2. Money Flow (No Funds Custody)

```
Sender (EU)                                          Recipient (Africa)
    │                                                        ▲
    │ 1. SEPA / Card pay-in                                  │
    ▼                                                        │
┌────────────────┐    2. webhook              ┌────────────────────────┐
│  Pay-in PSP    │ ───────────────────▶ wapaExchange API ──▶ Payout    │
│  (Stripe /     │                            │  (orchestrator,        │
│  TrueLayer)    │                            │   never custodies)     │
└────────────────┘                            └────────────────────────┘
        │                                              │ 3. payout call
        │ holds funds in PSP's segregated account      ▼
        │                                       ┌──────────────────┐
        │                                       │ Payout partner   │
        │ 4. settlement instruction to forward  │ (Thunes / MFS /  │
        ▼ funds directly to payout partner      │  Flutterwave)    │
┌────────────────┐                              └──────────────────┘
│  Pay-in PSP    │                                      │
│  forwards to   │                                      ▼
│  Payout PSP    │                              Mobile Money / Bank
└────────────────┘                              account of recipient
```

**Key point:** wapaExchange's bank account only receives **fees** (the FX margin + service fee), routed by the pay-in PSP after the payout is confirmed. Customer principal never enters our accounts.

## 3. iOS App Folder Structure

```
wapaExchange/
├── wapaExchangeApp.swift          // @main entry
├── ContentView.swift               // Root coordinator (auth-gated)
├── App/
│   └── AppState.swift              // Global @Observable state
├── Theme/
│   ├── AppColors.swift
│   ├── AppTypography.swift
│   └── AppSpacing.swift
├── Components/                     // Reusable views
│   ├── PrimaryButton.swift
│   ├── SecondaryButton.swift
│   ├── AppTextField.swift
│   ├── LoadingOverlay.swift
│   └── StatusPill.swift
├── Models/
│   ├── User.swift
│   ├── Recipient.swift
│   ├── Transaction.swift
│   ├── Quote.swift
│   └── Country.swift
├── Services/                       // API + persistence
│   ├── APIClient.swift
│   ├── AuthService.swift
│   ├── QuoteService.swift
│   ├── RecipientService.swift
│   ├── TransactionService.swift
│   └── KeychainHelper.swift
└── Features/                       // One folder per feature, MVVM
    ├── Splash/
    ├── Onboarding/
    ├── Auth/
    ├── Home/
    ├── Transfer/
    ├── Recipients/
    └── Transactions/
```

## 4. NestJS Backend Folder Structure

```
backend/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── common/
│   │   ├── decorators/      // @CurrentUser, @Roles
│   │   ├── guards/          // JwtAuthGuard, RolesGuard
│   │   ├── interceptors/    // Logging, RateLimit
│   │   ├── filters/         // GlobalExceptionFilter
│   │   └── pipes/           // ZodValidationPipe
│   ├── config/              // env, partners, fx, fees
│   ├── modules/
│   │   ├── auth/            // login, register, refresh, social
│   │   ├── users/           // profile, preferences
│   │   ├── kyc/             // start-session, webhook, status
│   │   ├── recipients/      // CRUD beneficiaries
│   │   ├── quotes/          // FX + fee calc
│   │   ├── transfers/       // orchestrator: pay-in → pay-out
│   │   ├── payins/          // Stripe / TrueLayer adapters
│   │   ├── payouts/         // Thunes / MFS / Flutterwave adapters
│   │   ├── webhooks/        // /webhooks/stripe, /sumsub, /thunes
│   │   ├── notifications/   // APNs, email, SMS
│   │   ├── compliance/      // AML hooks, sanctions, monitoring
│   │   └── support/         // ticket relay
│   └── infra/
│       ├── prisma/
│       ├── redis/
│       └── queues/
├── prisma/
│   └── schema.prisma
├── test/
├── Dockerfile
└── package.json
```

## 5. Security Architecture

| Layer | Control |
|---|---|
| **Transport** | TLS 1.3 only, HSTS, cert pinning on iOS for `api.wapaexchange.com` |
| **Auth** | Short-lived JWT (15 min) + refresh token (rotating, 30 days), stored in iOS Keychain (Secure Enclave–backed) |
| **Biometric** | Face ID / Touch ID gates session unlock via `LocalAuthentication` |
| **Device** | Device fingerprint sent on login (model + iOS version + app vendorID) — new device triggers email confirmation |
| **2FA** | TOTP enrollment after first transfer >€500 |
| **Backend secrets** | AWS Secrets Manager, IAM-scoped per ECS task |
| **PII at rest** | Postgres column-level encryption (pgcrypto) for full name, DOB, ID numbers |
| **KYC docs** | S3 bucket with SSE-KMS, presigned-URL access only, 7-year retention (AML legal hold) |
| **Logs** | No PII in logs; structured logs with Pino, shipped to CloudWatch |
| **Rate limiting** | Redis-backed, 60 req/min/user on quote endpoint, 10 req/min on auth |
| **Webhooks** | HMAC signature verification on every inbound webhook (Stripe, Sumsub, Thunes) |
| **PCI scope** | Reduced to SAQ-A: cards never touch our server, Stripe Elements / Apple Pay only |
| **GDPR** | Data deletion endpoint with AML legal-hold override (locked records retained 5 years) |
| **Audit log** | Append-only `audit_events` table, partitioned by month |

## 6. Future Scaling Strategy

| Phase | Trigger | Action |
|---|---|---|
| **Phase 2** (6 mo) | 5k MAU | Add Android (React Native or Kotlin), launch UK + Germany corridors |
| **Phase 3** (12 mo) | €5M monthly volume | Apply for own SPI (Small Payment Institution) license in France — €50k capital |
| **Phase 4** (18 mo) | €20M monthly volume | Migrate Postgres to Aurora, split monolith into 3 services (auth, transfers, ledger), add read replicas per region |
| **Phase 5** (24 mo) | Multi-region | Add Asia hub (Singapore), launch GCC corridor, integrate stablecoin rails (USDC via Circle) as a B2B backbone (still no end-user custody) |
