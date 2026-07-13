'use client';

import { useEffect, useState } from 'react';

interface Component {
  name: string;
  status: 'operational' | 'degraded' | 'down';
}

interface StatusReport {
  status: 'operational' | 'degraded' | 'down';
  updated_at: string;
  components: Component[];
}

const API = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'https://api.wapaexchange.com/v1';

const DOT_CLASS: Record<Component['status'], string> = {
  operational: 'bg-success',
  degraded: 'bg-amber-500',
  down: 'bg-danger',
};

const HEADLINE: Record<StatusReport['status'], { title: string; sub: string; bg: string }> = {
  operational: {
    title: 'All systems operational',
    sub: 'Everything is working as expected.',
    bg: 'from-emerald-500 to-emerald-700',
  },
  degraded: {
    title: 'Partial service degradation',
    sub: 'Some functionality may be slower than usual.',
    bg: 'from-amber-500 to-amber-700',
  },
  down: {
    title: 'Major outage',
    sub: 'We are working to restore service. Ongoing transfers are safe.',
    bg: 'from-rose-500 to-rose-700',
  },
};

export default function StatusPage() {
  const [report, setReport] = useState<StatusReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function fetchStatus() {
    try {
      const res = await fetch(`${API}/status`, { cache: 'no-store' });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      setReport(await res.json());
      setError(null);
    } catch (e) {
      setError((e as Error).message);
    }
  }

  useEffect(() => {
    void fetchStatus();
    const t = setInterval(fetchStatus, 30_000);
    return () => clearInterval(t);
  }, []);

  const headline = report ? HEADLINE[report.status] : HEADLINE.operational;

  return (
    <main className="min-h-screen">
      <div className={`bg-gradient-to-br ${headline.bg} text-white`}>
        <div className="mx-auto max-w-4xl px-6 py-16">
          <div className="flex items-center gap-3">
            <div className="grid h-8 w-8 place-items-center rounded-lg bg-white/20 text-white">↔︎</div>
            <span className="text-lg font-semibold">wapaExchange · Status</span>
          </div>
          <h1 className="mt-8 text-4xl font-bold md:text-5xl">{headline.title}</h1>
          <p className="mt-3 text-white/85">{headline.sub}</p>
          {report && (
            <p className="mt-6 text-sm text-white/70">
              Last checked {new Date(report.updated_at).toLocaleString()}
            </p>
          )}
        </div>
      </div>

      <section className="mx-auto max-w-4xl px-6 py-12">
        {error && (
          <div className="mb-6 rounded-lg bg-rose-50 p-4 text-sm text-rose-700">
            Could not reach the status API: {error}
          </div>
        )}
        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white">
          {(report?.components ?? []).map((c, i) => (
            <div
              key={c.name}
              className={`flex items-center justify-between px-6 py-5 ${i > 0 ? 'border-t border-slate-100' : ''}`}
            >
              <span className="font-medium">{c.name}</span>
              <div className="flex items-center gap-2 text-sm text-slate-600">
                <span className={`inline-block h-2.5 w-2.5 rounded-full ${DOT_CLASS[c.status]}`} />
                <span className="capitalize">{c.status}</span>
              </div>
            </div>
          ))}
          {!report && (
            <div className="px-6 py-8 text-center text-sm text-slate-500">Loading…</div>
          )}
        </div>

        <p className="mt-8 text-center text-xs text-slate-500">
          Auto-refreshes every 30 seconds. For incident history and subscriptions,{' '}
          <a href="mailto:status@wapaexchange.com" className="text-brand hover:underline">
            email us
          </a>
          .
        </p>
      </section>
    </main>
  );
}
