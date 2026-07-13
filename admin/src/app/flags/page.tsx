'use client';

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { api, getAccessToken, type ComplianceFlag } from '@/lib/api';

type Filter = 'open' | 'reviewing' | 'cleared' | 'all';

const SEVERITY_ORDER = { block: 0, high: 1, medium: 2, low: 3 } as const;

const SEVERITY_STYLES: Record<ComplianceFlag['severity'], string> = {
  block: 'bg-danger text-white',
  high: 'bg-danger/10 text-danger',
  medium: 'bg-warning/15 text-warning',
  low: 'bg-slate-100 text-slate-700',
};

export default function FlagsPage() {
  const router = useRouter();
  const [filter, setFilter] = useState<Filter>('open');
  const [flags, setFlags] = useState<ComplianceFlag[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [reviewing, setReviewing] = useState<ComplianceFlag | null>(null);

  useEffect(() => {
    if (!getAccessToken()) router.replace('/login');
  }, [router]);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const data = await api.listFlags(filter === 'all' ? undefined : filter);
      setFlags(data);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setLoading(false);
    }
  }
  useEffect(() => { void load(); /* eslint-disable-next-line react-hooks/exhaustive-deps */ }, [filter]);

  const sorted = useMemo(
    () => [...flags].sort((a, b) => {
      const s = SEVERITY_ORDER[a.severity] - SEVERITY_ORDER[b.severity];
      return s !== 0 ? s : (new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
    }),
    [flags],
  );

  return (
    <main className="min-h-screen">
      <nav className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-2">
            <div className="grid h-8 w-8 place-items-center rounded-lg bg-brand text-white">↔︎</div>
            <span className="text-lg font-semibold">Admin</span>
          </div>
          <div className="flex items-center gap-5 text-sm">
            <Link href="/flags" className="font-medium text-brand">Flags</Link>
            <Link href="/rate-limits" className="text-slate-600 hover:text-slate-900">Rate limits</Link>
            <button
              onClick={() => { api.logout(); router.replace('/login'); }}
              className="text-slate-500 hover:text-slate-900"
            >
              Sign out
            </button>
          </div>
        </div>
      </nav>

      <div className="mx-auto max-w-6xl px-6 py-8">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h1 className="text-2xl font-bold">Flags</h1>
          <div className="flex gap-2">
            {(['open', 'reviewing', 'cleared', 'all'] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`rounded-full px-4 py-1.5 text-sm font-medium transition ${
                  filter === f ? 'bg-brand text-white' : 'bg-white text-slate-700 hover:bg-slate-100'
                }`}
              >
                {f[0].toUpperCase() + f.slice(1)}
              </button>
            ))}
          </div>
        </div>

        {error && <div className="mt-4 rounded-lg bg-danger/10 p-4 text-sm text-danger">{error}</div>}

        <div className="mt-6 overflow-hidden rounded-2xl border border-slate-200 bg-white">
          <table className="w-full text-sm">
            <thead className="bg-slate-50 text-left text-xs uppercase tracking-wider text-slate-500">
              <tr>
                <th className="px-5 py-3">Severity</th>
                <th className="px-5 py-3">Rule</th>
                <th className="px-5 py-3">Reason</th>
                <th className="px-5 py-3">When</th>
                <th className="px-5 py-3">Status</th>
                <th className="px-5 py-3"></th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr><td colSpan={6} className="px-5 py-8 text-center text-slate-400">Loading…</td></tr>
              )}
              {!loading && sorted.length === 0 && (
                <tr><td colSpan={6} className="px-5 py-8 text-center text-slate-400">No flags.</td></tr>
              )}
              {sorted.map((flag) => (
                <tr key={flag.id} className="border-t border-slate-100">
                  <td className="px-5 py-4">
                    <span className={`rounded px-2 py-1 text-xs font-bold ${SEVERITY_STYLES[flag.severity]}`}>
                      {flag.severity.toUpperCase()}
                    </span>
                  </td>
                  <td className="px-5 py-4 font-mono text-xs">{flag.rule_id}</td>
                  <td className="px-5 py-4 text-slate-600">{flag.reason}</td>
                  <td className="px-5 py-4 text-slate-500">{new Date(flag.created_at).toLocaleString()}</td>
                  <td className="px-5 py-4 text-slate-500 capitalize">{flag.status}</td>
                  <td className="px-5 py-4 text-right">
                    {flag.status === 'open' && (
                      <button
                        onClick={() => setReviewing(flag)}
                        className="rounded-lg bg-brand px-3 py-1.5 text-xs font-semibold text-white hover:bg-brand-dark"
                      >
                        Review
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {reviewing && (
        <ReviewModal
          flag={reviewing}
          onClose={() => setReviewing(null)}
          onReviewed={() => {
            setReviewing(null);
            void load();
          }}
        />
      )}
    </main>
  );
}

function ReviewModal({
  flag, onClose, onReviewed,
}: {
  flag: ComplianceFlag;
  onClose: () => void;
  onReviewed: () => void;
}) {
  const [decision, setDecision] = useState<'cleared' | 'escalated'>('cleared');
  const [note, setNote] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    if (note.trim().length < 3) return;
    setSubmitting(true);
    setError(null);
    try {
      await api.reviewFlag(flag.id, decision, note.trim());
      onReviewed();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 grid place-items-center bg-black/40 px-4" onClick={onClose}>
      <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl" onClick={(e) => e.stopPropagation()}>
        <h2 className="text-lg font-bold">Review flag</h2>
        <dl className="mt-4 space-y-2 text-sm">
          <div className="flex justify-between"><dt className="text-slate-500">Rule</dt><dd className="font-mono">{flag.rule_id}</dd></div>
          <div className="flex justify-between"><dt className="text-slate-500">Severity</dt><dd className="capitalize">{flag.severity}</dd></div>
          <div><dt className="text-slate-500">Reason</dt><dd>{flag.reason}</dd></div>
        </dl>

        <div className="mt-5 flex gap-2 rounded-lg bg-slate-100 p-1 text-sm font-medium">
          <button
            onClick={() => setDecision('cleared')}
            className={`flex-1 rounded-md py-2 ${decision === 'cleared' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-600'}`}
          >
            Clear (false positive)
          </button>
          <button
            onClick={() => setDecision('escalated')}
            className={`flex-1 rounded-md py-2 ${decision === 'escalated' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-600'}`}
          >
            Escalate (file STR)
          </button>
        </div>

        <label className="mt-4 block text-sm font-medium">Reviewer note (audit trail)</label>
        <textarea
          value={note}
          onChange={(e) => setNote(e.target.value)}
          minLength={3}
          rows={4}
          className="mt-1 w-full rounded-lg border border-slate-200 px-3 py-2 focus:border-brand focus:outline-none"
        />

        {error && <p className="mt-2 text-sm text-danger">{error}</p>}

        <div className="mt-5 flex justify-end gap-2">
          <button onClick={onClose} className="rounded-lg px-4 py-2 text-sm text-slate-600 hover:bg-slate-100">
            Cancel
          </button>
          <button
            onClick={submit}
            disabled={submitting || note.trim().length < 3}
            className="rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-white hover:bg-brand-dark disabled:opacity-60"
          >
            {submitting ? 'Submitting…' : 'Submit'}
          </button>
        </div>
      </div>
    </div>
  );
}
