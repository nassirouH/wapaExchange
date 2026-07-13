# wapaExchange — Web

Marketing landing page. Static export — deployable to S3 + CloudFront, Vercel, Netlify, or any CDN.

## Run locally

```bash
cd web
npm install
npm run dev          # http://localhost:3000
```

## Build for production

```bash
npm run build        # writes to ./out
```

Upload the contents of `./out` to your bucket. With CloudFront, set the default root object to `index.html`.

## Edit content

- Hero copy + features + corridors live in `src/app/page.tsx`
- Tailwind colours (brand / accent) in `tailwind.config.ts`
- Global page metadata + OpenGraph in `src/app/layout.tsx`
- Replace the `https://formspree.io/f/REPLACE-ME` waitlist form action with your real Formspree (or Convertkit, Mailchimp, etc.) endpoint
