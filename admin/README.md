# wapaExchange — Admin Dashboard

Compliance review console for AML flags. Static-exported Next.js — deployable behind Cloudflare Access / VPN / Tailscale to restrict to staff.

## Run locally

```bash
cd admin
npm install
npm run dev    # http://localhost:3001
```

The dashboard reads `NEXT_PUBLIC_API_BASE_URL`, defaulting to `http://localhost:3000/v1`. Make sure the backend is running first.

## Build for production

```bash
npm run build                          # outputs ./out
NEXT_PUBLIC_API_BASE_URL=https://api.wapaexchange.com/v1 npm run build
```

## Access control

The dashboard hits `/v1/admin/compliance/flags` which is `JwtAuthGuard`-protected today. Production should add:

1. A `@Roles('compliance_officer')` guard on `ComplianceController` so non-officer JWTs can't read flags.
2. Network-level gating: deploy `./out` behind **Cloudflare Access** / **AWS VPN** / **Tailscale ACL** so the UI itself isn't world-reachable.
3. SSO via Google Workspace OIDC instead of email + password (saves you from rotating shared passwords).
