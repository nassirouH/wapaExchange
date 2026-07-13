/**
 * OpenTelemetry initialisation. Must be `require`d before any other module so
 * the auto-instrumentations can patch http/express/pg/ioredis at load time.
 *
 * Env knobs:
 *   OTEL_SERVICE_NAME           — service name in traces. Default "wapaexchange-api".
 *   OTEL_EXPORTER_OTLP_ENDPOINT — collector URL. Default unset → disabled (no-op).
 *   OTEL_EXPORTER_OTLP_HEADERS  — auth headers if your collector requires them.
 */
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { resourceFromAttributes } from '@opentelemetry/resources';
import { ATTR_SERVICE_NAME, ATTR_SERVICE_VERSION } from '@opentelemetry/semantic-conventions';

let sdk: NodeSDK | null = null;

export function startTracing() {
  if (!process.env.OTEL_EXPORTER_OTLP_ENDPOINT) {
    // Tracing disabled — no exporter configured. Keep it cheap in local dev.
    return;
  }

  sdk = new NodeSDK({
    resource: resourceFromAttributes({
      [ATTR_SERVICE_NAME]: process.env.OTEL_SERVICE_NAME ?? 'wapaexchange-api',
      [ATTR_SERVICE_VERSION]: process.env.APP_VERSION ?? '0.1.0',
      'deployment.environment': process.env.NODE_ENV ?? 'development',
      'service.role': process.env.ROLE ?? 'api',
    }),
    traceExporter: new OTLPTraceExporter({
      url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT,
    }),
    instrumentations: [
      getNodeAutoInstrumentations({
        // Don't instrument fs — way too noisy and not useful.
        '@opentelemetry/instrumentation-fs': { enabled: false },
        // Trim HTTP spans: skip the health checks (they pollute the trace volume).
        '@opentelemetry/instrumentation-http': {
          ignoreIncomingRequestHook: (req) =>
            req.url?.includes('/v1/health') ?? false,
        },
      }),
    ],
  });

  sdk.start();

  process.on('SIGTERM', () => {
    sdk?.shutdown().catch((err) => console.error('OTel shutdown error', err));
  });
}
