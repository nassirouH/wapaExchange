# wapaExchange — User Flows

## Flow 1: Onboarding & First Transfer

```
[Splash]
   │
   ▼
[Onboarding carousel: 3 slides]
   │
   ▼
[Register OR Login]
   │
   ▼ (new user)
[Verify email]
   │
   ▼
[KYC: take selfie + ID via Sumsub SDK]
   │
   ▼ (status = pending → push when approved)
[Home Dashboard]   ◀───────────────┐
   │                                │
   ▼                                │
[Tap "Send money"]                  │
   │                                │
   ▼                                │
[Enter amount + country]            │
   │                                │
   ▼                                │
[Quote: shows rate, fee, recipient gets]
   │                                │
   ▼                                │
[Pick recipient — existing or +Add] │
   │                                │
   ▼                                │
[Confirm + pay (Apple Pay / SEPA)]  │
   │                                │
   ▼                                │
[Receipt + tracking screen] ────────┘
```

## Flow 2: Repeat Transfer (Power User)

```
[Home]
   │  Quick action: "Send to Aïcha"  (favorite recipient)
   ▼
[Quote pre-filled with last amount]
   │
   ▼
[Confirm + Apple Pay]
   │
   ▼
[Tracking]
```
Target: <30s from app open to confirmation.

## Flow 3: Transfer State Machine

```
   ┌──────────────┐
   │ pending_payin│
   └──────┬───────┘
          │ payin webhook OK
          ▼
   ┌──────────────┐         ┌──────────┐
   │payin_received│────────▶│  failed  │ (pay-in declined)
   └──────┬───────┘         └──────────┘
          │ payout call placed
          ▼
   ┌──────────────┐
   │  forwarded   │
   └──────┬───────┘
          │ partner pickup
          ▼
   ┌──────────────┐
   │payout_pending│
   └──────┬───────┘
          │ partner success webhook
          ▼
   ┌──────────────┐
   │payout_complete│ ─────▶ push: "Aïcha received €100"
   └──────────────┘
```

Failure handling: if `payout` fails after `payin_received`, status → `refunded`, pay-in PSP refund triggered, push notifies sender.

## Flow 4: KYC Rejection Recovery

```
[Push: "KYC needs another doc"]
   │
   ▼
[Home banner: amber, "Complete verification"]
   │
   ▼
[Reopen Sumsub SDK with same applicant ID]
   │
   ▼
[Re-submit document]
   │
   ▼ (approved)
[Push: "You're verified"]
```
