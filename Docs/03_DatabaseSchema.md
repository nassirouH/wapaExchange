# wapaExchange — Database Schema (PostgreSQL)

All tables use `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`, `created_at`, `updated_at`. Soft-delete via `deleted_at` where relevant.

## users
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| email | citext | unique |
| phone | varchar(20) | E.164, unique-nullable |
| password_hash | text | bcrypt, nullable for social |
| auth_provider | enum | `email`, `apple`, `google` |
| full_name | text | encrypted (pgcrypto) |
| date_of_birth | date | encrypted |
| address_line1, city, postal_code, country | text/varchar | sender residence |
| kyc_status | enum | `not_started`, `pending`, `approved`, `rejected` |
| kyc_provider_ref | text | Sumsub/Onfido applicant ID |
| risk_score | int | 0–100, set by AML engine |
| created_at, updated_at, deleted_at | timestamptz | |

## refresh_tokens
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK users |
| token_hash | text | SHA-256 of refresh token |
| device_fingerprint | text | |
| expires_at | timestamptz | |
| revoked_at | timestamptz | |

## recipients
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK users (owner) |
| full_name | text | encrypted |
| country | char(2) | ISO 3166-1 alpha-2 |
| payout_method | enum | `mobile_money`, `bank_transfer` |
| mobile_money_provider | enum-nullable | `orange`, `mtn`, `wave`, `mpesa`, `airtel` |
| mobile_money_number | varchar(20) | encrypted |
| bank_name | text | nullable |
| bank_account_number | text | encrypted, nullable |
| bank_swift_or_iban | text | nullable |
| is_favorite | bool | default false |
| last_used_at | timestamptz | for "recents" ordering |
| created_at, updated_at, deleted_at | | |

## quotes
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK |
| send_currency | char(3) | EUR |
| send_amount | numeric(14,2) | |
| receive_currency | char(3) | XOF, NGN, KES… |
| receive_amount | numeric(14,2) | |
| fx_rate | numeric(18,8) | mid-rate from FX feed |
| fx_margin_bps | int | our markup, basis points |
| fee_amount | numeric(10,2) | service fee |
| total_pay | numeric(14,2) | send_amount + fee_amount |
| payout_method | enum | |
| destination_country | char(2) | |
| expires_at | timestamptz | quote TTL, default 5 min |
| created_at | | |

## transfers
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK |
| quote_id | uuid | FK quotes |
| recipient_id | uuid | FK recipients |
| status | enum | `pending_payin`, `payin_received`, `forwarded`, `payout_pending`, `payout_complete`, `failed`, `refunded` |
| payin_provider | enum | `stripe`, `truelayer`, `applepay` |
| payin_reference | text | PSP charge / payment intent id |
| payout_provider | enum | `thunes`, `mfs`, `flutterwave` |
| payout_reference | text | partner txn id |
| payout_country | char(2) | |
| send_amount, receive_amount, fee_amount, fx_rate | | snapshot at confirm time |
| failure_code | text | nullable |
| created_at, updated_at | | |

## transfer_events
Append-only state-machine log.
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| transfer_id | uuid | FK |
| from_status | enum | |
| to_status | enum | |
| source | text | `system`, `webhook:stripe`, `webhook:thunes`, `manual` |
| metadata | jsonb | raw webhook payload |
| created_at | | |

## kyc_sessions
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK |
| provider | enum | `sumsub`, `onfido`, `veriff` |
| provider_session_id | text | |
| status | enum | `init`, `in_review`, `approved`, `rejected`, `expired` |
| rejection_reason | text | nullable |
| documents | jsonb | metadata only — actual files in S3 |
| created_at, updated_at | | |

## audit_events
Append-only. Partition by `created_at` (monthly).
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| actor_user_id | uuid | nullable |
| actor_admin_id | uuid | nullable |
| action | text | `login`, `kyc_approved`, `transfer_created`, … |
| resource_type, resource_id | text/uuid | |
| ip_address | inet | |
| user_agent | text | |
| metadata | jsonb | |
| created_at | timestamptz | |

## notification_log
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK |
| channel | enum | `push`, `email`, `sms` |
| template | text | |
| payload | jsonb | |
| sent_at | timestamptz | |
| delivery_status | enum | `queued`, `sent`, `delivered`, `failed` |

## fx_rates (cache)
| Column | Type | Notes |
|---|---|---|
| pair | varchar(7) | e.g. `EUR_XOF` (PK) |
| mid_rate | numeric(18,8) | |
| source | text | `openexchangerates`, `wise_api` |
| fetched_at | timestamptz | |
