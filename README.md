# wapaExchange

Mobile-first remittance from Europe to Africa & Asia. Zero-custody design: funds
flow through licensed PSD2 partners while we own the UX and take a transparent
FX margin + service fee.

## Repo layout

| Path | What |
|---|---|
| `wapaExchange/` | iOS app — SwiftUI, MVVM, async/await, Xcode 16 filesystem-sync group |
| `wapaExchange.xcodeproj/` | Xcode project |
| `wapaExchangeUITests/` | XCUIAutomation golden-path tests |
| `backend/` | NestJS 10 + Prisma + Postgres + Redis + BullMQ, Docker-ready |
| `web/` | Marketing site (Next.js 15 static export) |
| `admin/` | Compliance-officer dashboard (Next.js 15, Google SSO) |
| `infrastructure/terraform/` | AWS eu-west-3 stack (VPC, RDS, Redis, ECS, ALB, S3) |
| `loadtest/` | k6 mixed-load scripts |
| `Docs/` | PRD, architecture, DB schema, API, user flows, roadmap, partner outreach |
| `mkdocs.yml` | Docs site config, published to GitHub Pages |
| `.github/workflows/` | CI/CD for all 4 deliverable stacks |

## Connect backend and hosting (prod)

Set these GitHub repo secrets before deploying from `main`:

| Secret | Used by | Example |
|---|---|---|
| `AWS_DEPLOY_ROLE_ARN` | `backend-deploy`, `admin-deploy`, `web-deploy` | `arn:aws:iam::123456789012:role/github-actions-deploy` |
| `WEB_S3_BUCKET` | `web-deploy` | `wapa-web-prod` |
| `WEB_CLOUDFRONT_ID` | `web-deploy` | `E123ABC456DEF` |
| `WEB_API_BASE_URL` | `web-deploy` | `https://api.wapaexchange.com/v1` |
| `ADMIN_S3_BUCKET` | `admin-deploy` | `wapa-admin-prod` |
| `ADMIN_CLOUDFRONT_ID` | `admin-deploy` | `E123ABC456XYZ` |
| `ADMIN_API_BASE_URL` | `admin-deploy` | `https://api.wapaexchange.com/v1` |
| `AWS_DEPLOY_ROLE_ARN` | `backend-deploy` | `arn:aws:iam::123456789012:role/github-actions-deploy` |

Then configure Terraform prod vars in `infrastructure/terraform/envs/prod/terraform.tfvars`:

```hcl
domain_name         = "api.wapaexchange.com"
acm_certificate_arn = "arn:aws:acm:eu-west-3:123456789012:certificate/REPLACE-ME"
container_image     = "123456789012.dkr.ecr.eu-west-3.amazonaws.com/wapaexchange:latest"
cors_origin         = "https://admin.wapaexchange.com,https://wapaexchange.com"
```

Deploy order:

1. Apply Terraform in `infrastructure/terraform/envs/prod`.
2. Push backend changes to trigger `backend-deploy`.
3. Push admin/web changes to trigger static site deploys.
4. Verify `https://api.../v1/health` and admin/web pages can call the API.

## Running the stack locally

```bash
# 1. Backend (Postgres 16 + Redis 8 + NestJS)
brew install postgresql@16 redis      # one-time
brew services start postgresql@16 redis
createuser -s wapa && createdb -O wapa wapaexchange
cd backend
cp .env.example .env
npm install
npx prisma migrate dev
npm run start:dev                     # API on :3000, Swagger at :3000/v1/docs

# 2. Backend worker (BullMQ payouts + refunds)
cd backend
npm run start:worker                  # separate terminal

# 3. Marketing site
cd web
npm install
npm run dev                           # http://localhost:3000

# 4. Admin dashboard
cd admin
npm install
npm run dev                           # http://localhost:3001

# 5. Docs site
pip install mkdocs-material
mkdocs serve                          # http://127.0.0.1:8000

# 6. iOS app
open wapaExchange.xcodeproj
# Then use Xcode UI — see manual steps below.
```

---

## Manual steps in Xcode (I can't do these — pbxproj edits are policy-blocked)

Do these **once** and everything else automates. Approximate total time: **30 minutes**, most of it waiting on Sumsub approval.

### A · Code signing (5 min, required to run at all)

1. Xcode → **Settings → Accounts** → **+** → **Apple ID** → sign in.
2. Left nav → click the blue **wapaExchange** project icon.
3. TARGETS → **wapaExchange** → **Signing & Capabilities**.
4. ☑ **Automatically manage signing** → **Team** = your Personal Team.
5. **Bundle Identifier** — change to something unique (e.g. `com.nassirou.wapaexchange`).

### B · Swift Package dependencies (5 min, gives you Stripe / KYC / crash reporting for real)

Xcode → **File → Add Package Dependencies…** — add each of these URLs, then tick the listed product and add it to the **wapaExchange** target:

| URL | Product | What it enables |
|---|---|---|
| `https://github.com/stripe/stripe-ios` | **StripePaymentSheet** | Real Apple Pay / SEPA / card pay-in via `Integrations/StripePayin.swift` |
| `https://github.com/SumSubstance/IdensicMobileSDK-spm` | **IdensicMobileSDK** | Real ID + selfie + liveness via `Integrations/SumsubKYC.swift` |
| `https://github.com/getsentry/sentry-cocoa` | **Sentry** | Real crash reporting via `Integrations/SentryClient.swift` |

All three integration files use `#if canImport(…)` — until you add these, the app still compiles with graceful stubs.

### C · Info.plist keys (2 min, required for camera + push)

Same tab as signing → **Info** → **Custom iOS Target Properties** → **+** for each row:

| Key | Type | Value |
|---|---|---|
| Privacy - Camera Usage Description | String | Used to capture your ID and selfie for identity verification. |
| Privacy - Microphone Usage Description | String | Required for the liveness check during verification. |
| STRIPE_PUBLISHABLE_KEY | String | `pk_test_…` from your Stripe dashboard |
| WAPA_API_BASE_URL | String | `http://localhost:3000/v1` for dev, real URL for prod |
| WAPA_USE_MOCK | Boolean | `NO` once the backend is up |
| SENTRY_DSN | String | Your Sentry project DSN, or blank to disable |

### D · Capabilities (1 min)

**Signing & Capabilities** → **+ Capability**:
- **Push Notifications** — required for APNs (`Integrations/PushNotifications.swift`).

### E · UI Test target (2 min, to unlock the CI UI-tests job)

**File → New → Target → UI Testing Bundle** → name it `wapaExchangeUITests`. The file at `wapaExchangeUITests/GoldenPathUITests.swift` is auto-included via filesystem-sync. CI will run it automatically once the target exists.

---

## External accounts to create

None of these require your credit card until you move to production. All have free sandbox tiers.

| Provider | What for | Approval time | Where the creds go |
|---|---|---|---|
| **Apple Developer** | Signing the app for TestFlight / App Store | Instant (free) or ~24h (paid €99/yr) | Xcode → Settings → Accounts |
| **Stripe** | Pay-in (Apple Pay, SEPA, cards) | Instant | `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` in `backend/.env` + `STRIPE_PUBLISHABLE_KEY` in iOS Info.plist |
| **Sumsub** | KYC (ID + liveness) | ~24-48h manual | `SUMSUB_APP_TOKEN`, `SUMSUB_SECRET_KEY`, `SUMSUB_WEBHOOK_SECRET` in `backend/.env` |
| **Thunes** | Payouts (Orange Money, MTN, M-Pesa, banks) | 1-3 business days, B2B onboarding | `THUNES_API_KEY`, `THUNES_API_SECRET` in `backend/.env` |
| **Google Cloud (OAuth)** | Admin dashboard SSO | Instant | `GOOGLE_OAUTH_CLIENT_ID` in `backend/.env` + `NEXT_PUBLIC_GOOGLE_CLIENT_ID` in `admin/.env` |
| **Sentry** | Crash + error monitoring (backend + iOS) | Instant | `SENTRY_DSN` in both `backend/.env` and iOS Info.plist |
| **ngrok** | Expose local backend to partner webhooks | Instant free tier | `ngrok config add-authtoken …` |
| **A licensed PI/EMI partner** | The regulatory foundation (see `Docs/07_Partner_Outreach.md`) | 6–10 weeks | Contract, not env vars |

## Provisioning your first admin user

The admin dashboard is gated by `AdminGuard` — only users with `is_admin = true` in the `users` table can hit `/v1/admin/*`. Bootstrap yourself after signing up via the iOS app or Google SSO:

```bash
psql wapaexchange -c "UPDATE users SET is_admin = true WHERE email = 'you@wapaexchange.com';"
```

## The one rule

**wapaExchange never holds customer money.** Every architectural decision — the
Stripe → Thunes flow-through, the transfer state machine, the `transfer_events`
append-only log, the refund-on-payout-failure listener, the RFC 7807 error
contract — flows from that single constraint. If a design choice ever routes
principal through our own bank account, back it out.

## Where to look next

- **First transfer in mock mode:** `wapaExchange/Docs/05_UserFlows.md`
- **What the money-flow actually looks like:** `wapaExchange/Docs/02_Architecture.md` §2
- **How to price for a new corridor:** `wapaExchange/Docs/06_Roadmap_Revenue_Costs.md`
- **What to send Lemonway / MangoPay:** `wapaExchange/Docs/07_Partner_Outreach.md`
