/**
 * Sentry initialisation. Must be `require`d before any other module so its
 * auto-instrumentations can hook into http/express at load time.
 *
 * Env:
 *   SENTRY_DSN              — disabled if empty (default in dev).
 *   SENTRY_ENVIRONMENT      — "production", "staging", etc.
 *   SENTRY_TRACES_SAMPLE_RATE — 0.0..1.0, default 0.1 in prod, 0 elsewhere.
 *   SENTRY_PROFILES_SAMPLE_RATE — same, default 0.
 *   APP_VERSION             — release tag (CI sets this to the commit sha).
 */
import * as Sentry from '@sentry/node';
import { nodeProfilingIntegration } from '@sentry/profiling-node';

export function startSentry() {
  const dsn = process.env.SENTRY_DSN;
  if (!dsn) return;

  Sentry.init({
    dsn,
    environment: process.env.SENTRY_ENVIRONMENT ?? process.env.NODE_ENV ?? 'development',
    release: process.env.APP_VERSION,
    tracesSampleRate: Number(process.env.SENTRY_TRACES_SAMPLE_RATE ?? (process.env.NODE_ENV === 'production' ? 0.1 : 0)),
    profilesSampleRate: Number(process.env.SENTRY_PROFILES_SAMPLE_RATE ?? 0),
    integrations: [nodeProfilingIntegration()],
    // Strip request bodies that may contain credentials.
    beforeSend(event) {
      if (event.request?.data) {
        event.request.data = '[REDACTED]';
      }
      return event;
    },
  });
}

export { Sentry };
