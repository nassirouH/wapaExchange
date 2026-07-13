'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { getAccessToken } from '@/lib/api';

interface HourBucket { hour: string; hits: number; throttled: number; }
interface RouteMetrics {
  method: string;
  route: string;
  buckets: HourBucket[];
  total_hits: number;
  total_throttled: number;
  throttle_rate: number;
}

const API = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000/v1';

export default function RateLimitsPage() {
  const router = useRouter();
  const [routes, setRoutes] = useState<RouteMetrics[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!getAccessToken()) router.replace('/login');
  }, [router]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const token = getAccessToken();
      const res = await fetch(`${API}/admin/metrics/rate-limits`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      setRoutes(await res.json());
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void load();
    const t = setInterval(load, 60_000);
    return () => clearInterval(t);
  }, []);

  const totalHits = routes.reduce((s, r) => s + r.total_hits, 0);
  const totalThrottled = routes.reduce((s, r) => s + r.total_throttled, 0);

  return (
    <main className="min-h-screen">
      <nav className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-2">
            <div className="grid h-8 w-8 place-items-center rounded-lg bg-brand text-white">↔︎</div>
            <span className="text-lg font-semibold">Admin</span>
          </div>
          <div className="flex gap-4 text-sm">
            <Link href="/flags" className="text-slate-600 hover:text-slate-900">Flags</Link>
            <Link href="/rate-limits" className="font-medium text-brand">Rate limits</Link>
          </div>
        </div>
      </nav>

      <div className="mx-auto max-w-6xl px-6 py-8">
        <h1 className="text-2xl font-bold">Rate limits — last 24h</h1>
        <p className="mt-1 text-sm text-slate-500">Hourly buckets, auto-refreshes every 60 seconds.</p>

        <div className="mt-6 grid gap-4 sm:grid-cols-3">
          <SummaryCard label="Requests" value={totalHits.toLocaleString()} />
          <SummaryCard label="Throttled (429)" value={totalThrottled.toLocaleString()} tone={totalThrottled > 0 ? 'warning' : undefined} />
          <SummaryCard
            label="Throttle rate"
            value={totalHits > 0 ? `${((totalThrottled / totalHits) * 100).toFixed(2)}%` : '0%'}
            tone={totalHits > 0 && totalThrottled / totalHits > 0.01 ? 'danger' : undefined}
          />
        </div>

        {error && <div className="mt-6 rounded-lg bg-danger/10 p-4 text-sm text-danger">{error}</div>}

        <div className="mt-8 space-y-4">
          {loading && routes.length === 0 && <div className="text-sm text-slate-400">Loading…</div>}
          {!loading && routes.length === 0 && !error && (
            <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center text-sm text-slate-500">
              No traffic recorded yet. Make some API requests to populate this dashboard.
            </div>
          )}
          {routes.map((r) => <RouteRow key={`${r.method}:${r.route}`} route={r} />)}
        </div>
      </div>
    </main>
  );
}

function SummaryCard({ label, value, tone }: { label: string; value: string; tone?: 'warning' | 'danger' }) {
  const toneClass = tone === 'danger' ? 'text-danger' : tone === 'warning' ? 'text-warning' : 'text-slate-900';
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5">
      <div className="text-xs uppercase tracking-wider text-slate-500">{label}</div>
      <div className={`mt-2 text-3xl font-bold ${toneClass}`}>{value}</div>
    </div>
  );
}

function RouteRow({ route }: { route: RouteMetrics }) {
  // Normalise buckets to a 24-hour window ending now, filling missing hours with 0.
  const nowHour = Math.floor(Date.now() / 3_600_000);
  const cells: HourBucket[] = Array.from({ length: 24 }, (_, i) => {
    const bucketEpoch = nowHour - (23 - i);
    const hourIso = new Date(bucketEpoch * 3_600_000).toISOString();
    return route.buckets.find((b) => b.hour === hourIso) ?? { hour: hourIso, hits: 0, throttled: 0 };
  });
  const peakHits = Math.max(1, ...cells.map((c) => c.hits));

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5">
      <div className="flex flex-wrap items-baseline justify-between gap-2">
        <div className="font-mono text-sm">
          <span className="mr-2 inline-block rounded bg-slate-100 px-2 py-0.5 text-xs font-bold">{route.method}</span>
          <span>{route.route}</span>
        </div>
        <div className="flex gap-4 text-xs text-slate-500">
          <span>{route.total_hits.toLocaleString()} hits</span>
          <span className={route.total_throttled > 0 ? 'text-warning' : ''}>
            {route.total_throttled} throttled
          </span>
          <span>{(route.throttle_rate * 100).toFixed(2)}%</span>
        </div>
      </div>
      {/* 24-cell heatmap — one per hour */}
      <div className="mt-3 flex gap-1">
        {cells.map((c, i) => {
          const intensity = Math.min(1, c.hits / peakHits);
          const bg = c.throttled > 0
            ? 'bg-danger'
            : intensity === 0
              ? 'bg-slate-100'
              : intensity < 0.33
                ? 'bg-brand/25'
                : intensity < 0.66
                  ? 'bg-brand/60'
                  : 'bg-brand';
          return (
            <div
              key={i}
              className={`h-6 flex-1 rounded ${bg}`}
              title={`${new Date(c.hour).toLocaleString()} · ${c.hits} hits · ${c.throttled} throttled`}
            />
          );
        })}
      </div>
      <div className="mt-1 flex justify-between text-[10px] text-slate-400">
        <span>24h ago</span>
        <span>now</span>
      </div>
    </div>
  );
}
