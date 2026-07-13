# wapaExchange — REST API Structure

Base URL (prod): `https://api.wapaexchange.com/v1`
All endpoints require `Authorization: Bearer <jwt>` unless marked **(public)**.
All responses `application/json`. Errors follow RFC 7807 problem-details.

## Auth

| Method | Path | Description |
|---|---|---|
| POST | `/auth/register` **(public)** | Create user (email + password). Returns 201 + sends email verification. |
| POST | `/auth/login` **(public)** | Email + password. Returns `{ access_token, refresh_token, user }`. |
| POST | `/auth/social` **(public)** | Apple / Google ID token exchange. |
| POST | `/auth/refresh` **(public)** | Rotate refresh token. |
| POST | `/auth/logout` | Revoke current refresh token. |
| POST | `/auth/forgot-password` **(public)** | |
| POST | `/auth/reset-password` **(public)** | |
| POST | `/auth/2fa/enroll` | TOTP enrollment. |
| POST | `/auth/2fa/verify` | |

## Users

| Method | Path | Description |
|---|---|---|
| GET | `/me` | Current user profile + KYC status. |
| PATCH | `/me` | Update profile. |
| DELETE | `/me` | GDPR deletion (subject to AML legal-hold). |

## KYC

| Method | Path | Description |
|---|---|---|
| POST | `/kyc/session` | Create a KYC session, returns provider SDK token. |
| GET | `/kyc/status` | Current applicant status. |
| POST | `/webhooks/kyc` **(public, HMAC)** | Provider callback. |

## Recipients

| Method | Path | Description |
|---|---|---|
| GET | `/recipients` | List, sorted by `last_used_at desc`. |
| POST | `/recipients` | Create. |
| GET | `/recipients/:id` | |
| PATCH | `/recipients/:id` | |
| DELETE | `/recipients/:id` | Soft delete. |
| POST | `/recipients/:id/favorite` | Toggle favorite. |

## Quotes

| Method | Path | Description |
|---|---|---|
| POST | `/quotes` | Body: `{ send_currency, send_amount, destination_country, payout_method }`. Returns quote with 5-min TTL. |
| GET | `/quotes/:id` | |
| GET | `/rates` **(public)** | Public mid-rate snapshot for marketing. |

## Transfers

| Method | Path | Description |
|---|---|---|
| POST | `/transfers` | Body: `{ quote_id, recipient_id, payin_method }`. Returns transfer + PSP client secret for pay-in. |
| GET | `/transfers` | List, paginated, filter by status/date. |
| GET | `/transfers/:id` | Detail + event log. |
| POST | `/transfers/:id/cancel` | Cancel before `payin_received`. |
| GET | `/transfers/:id/receipt` | PDF receipt (signed S3 URL). |

## Webhooks (server-to-server)

| Method | Path | Description |
|---|---|---|
| POST | `/webhooks/payin/stripe` | Stripe payment events. |
| POST | `/webhooks/payin/truelayer` | Open Banking pay-in events. |
| POST | `/webhooks/payout/thunes` | Payout status updates. |
| POST | `/webhooks/payout/mfs` | |
| POST | `/webhooks/payout/flutterwave` | |
| POST | `/webhooks/kyc/sumsub` | |

## Notifications

| Method | Path | Description |
|---|---|---|
| POST | `/notifications/device` | Register APNs token. |
| GET | `/notifications` | In-app inbox. |
| PATCH | `/notifications/:id/read` | |

## Support

| Method | Path | Description |
|---|---|---|
| POST | `/support/tickets` | Create ticket (relays to Intercom). |
| GET | `/support/tickets` | List user's tickets. |

## Error model

```json
{
  "type": "https://wapaexchange.com/errors/quote-expired",
  "title": "Quote expired",
  "status": 410,
  "detail": "Quote a1b2... expired at 2026-06-18T14:23:00Z",
  "instance": "/v1/transfers"
}
```
