'use client';

import Script from 'next/script';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';

/**
 * Google Identity Services sign-in button.
 * Fallback to email/password if NEXT_PUBLIC_GOOGLE_CLIENT_ID isn't configured
 * (useful for local development against a backend without SSO credentials).
 */

declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (opts: { client_id: string; callback: (res: { credential: string }) => void; hd?: string }) => void;
          renderButton: (el: HTMLElement, opts: Record<string, unknown>) => void;
          prompt: () => void;
        };
      };
    };
  }
}

const GOOGLE_CLIENT_ID = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? '';
const GOOGLE_HD = process.env.NEXT_PUBLIC_GOOGLE_HD;

export default function LoginPage() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [showFallback, setShowFallback] = useState(!GOOGLE_CLIENT_ID);

  useEffect(() => {
    if (!GOOGLE_CLIENT_ID) return;
    const tick = setInterval(() => {
      if (!window.google?.accounts?.id) return;
      clearInterval(tick);
      window.google.accounts.id.initialize({
        client_id: GOOGLE_CLIENT_ID,
        hd: GOOGLE_HD,
        callback: async (response) => {
          try {
            await api.loginWithGoogle(response.credential);
            router.replace('/flags');
          } catch (err) {
            setError((err as Error).message);
          }
        },
      });
      const target = document.getElementById('gsi-button');
      if (target) {
        window.google.accounts.id.renderButton(target, {
          theme: 'filled_blue', size: 'large', width: 320,
        });
      }
    }, 100);
    return () => clearInterval(tick);
  }, [router]);

  return (
    <>
      <Script src="https://accounts.google.com/gsi/client" strategy="afterInteractive" />
      <main className="grid min-h-screen place-items-center px-6">
        <div className="w-full max-w-sm rounded-2xl bg-white p-8 shadow-sm">
          <div className="flex items-center gap-2">
            <div className="grid h-8 w-8 place-items-center rounded-lg bg-brand text-white">↔︎</div>
            <span className="text-lg font-semibold">wapaExchange Admin</span>
          </div>
          <h1 className="mt-6 text-2xl font-bold">Sign in</h1>
          <p className="mt-1 text-sm text-slate-500">
            Compliance review console. Restricted to authorised staff.
          </p>

          {GOOGLE_CLIENT_ID ? (
            <>
              <div id="gsi-button" className="mt-6 flex justify-center" />
              <button
                onClick={() => setShowFallback((v) => !v)}
                className="mt-4 block w-full text-center text-xs text-slate-400 hover:text-slate-600"
              >
                {showFallback ? 'Hide password sign-in' : 'Use password sign-in instead'}
              </button>
            </>
          ) : (
            <p className="mt-4 rounded bg-warning/10 p-3 text-xs text-warning">
              Google SSO not configured (set <code>NEXT_PUBLIC_GOOGLE_CLIENT_ID</code>).
              Using password fallback.
            </p>
          )}

          {showFallback && <PasswordForm onError={setError} onSuccess={() => router.replace('/flags')} />}

          {error && <p className="mt-3 text-sm text-danger">{error}</p>}
        </div>
      </main>
    </>
  );
}

function PasswordForm({ onError, onSuccess }: { onError: (e: string) => void; onSuccess: () => void }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    try {
      await api.login(email, password);
      onSuccess();
    } catch (err) {
      onError((err as Error).message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={submit} className="mt-4 space-y-3">
      <input
        type="email"
        required
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        className="w-full rounded-lg border border-slate-200 px-3 py-2 focus:border-brand focus:outline-none"
      />
      <input
        type="password"
        required
        minLength={6}
        placeholder="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        className="w-full rounded-lg border border-slate-200 px-3 py-2 focus:border-brand focus:outline-none"
      />
      <button
        type="submit"
        disabled={loading}
        className="w-full rounded-lg bg-brand py-2.5 font-semibold text-white hover:bg-brand-dark disabled:opacity-60"
      >
        {loading ? 'Signing in…' : 'Sign in with password'}
      </button>
    </form>
  );
}
