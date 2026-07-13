import Link from 'next/link';

const CORRIDORS = [
  { flag: '🇸🇳', name: 'Senegal', currency: 'XOF' },
  { flag: '🇨🇮', name: "Côte d'Ivoire", currency: 'XOF' },
  { flag: '🇳🇬', name: 'Nigeria', currency: 'NGN' },
  { flag: '🇬🇭', name: 'Ghana', currency: 'GHS' },
  { flag: '🇰🇪', name: 'Kenya', currency: 'KES' },
  { flag: '🇨🇲', name: 'Cameroon', currency: 'XAF' },
];

const FEATURES = [
  {
    icon: '⚡',
    title: 'Minutes, not days',
    body: 'Mobile money and bank transfers settle within minutes, not the 1–3 business days of traditional providers.',
  },
  {
    icon: '💸',
    title: 'Honest rates',
    body: 'Real-time mid-market rates with a flat, transparent fee. We never pad the FX rate.',
  },
  {
    icon: '🛡️',
    title: 'Licensed and audited',
    body: 'Funds flow through PSD2-licensed payment institutions, KYC handled by Sumsub, sanctions screening on every transfer.',
  },
];

export default function Home() {
  return (
    <main className="min-h-screen">
      <nav className="border-b border-slate-100">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-2">
            <div className="grid h-8 w-8 place-items-center rounded-lg bg-brand text-white">↔︎</div>
            <span className="text-lg font-semibold">wapaExchange</span>
          </div>
          <div className="flex items-center gap-6 text-sm">
            <Link href="#features" className="text-slate-600 hover:text-slate-900">Features</Link>
            <Link href="#corridors" className="text-slate-600 hover:text-slate-900">Where we send</Link>
            <Link href="#waitlist" className="rounded-full bg-brand px-4 py-2 font-medium text-white hover:bg-brand-dark transition">
              Join waitlist
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="relative overflow-hidden bg-gradient-to-br from-brand to-brand-dark text-white">
        <div className="mx-auto grid max-w-6xl gap-12 px-6 py-24 md:grid-cols-2 md:items-center md:py-32">
          <div>
            <span className="inline-block rounded-full bg-white/15 px-3 py-1 text-xs font-semibold uppercase tracking-wider">
              Coming soon — France · Germany
            </span>
            <h1 className="mt-6 text-5xl font-bold leading-tight md:text-6xl">
              Send money home, <br />fairly.
            </h1>
            <p className="mt-6 max-w-lg text-lg text-white/90">
              Europe → Africa & Asia in minutes. Real-time exchange rates, a flat fee
              you can see before you pay. No surprises, no hidden margins.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Link
                href="#waitlist"
                className="rounded-full bg-white px-6 py-3 font-semibold text-brand hover:bg-slate-100"
              >
                Get early access
              </Link>
              <Link
                href="#features"
                className="rounded-full border border-white/30 px-6 py-3 font-semibold text-white hover:bg-white/10"
              >
                How it works
              </Link>
            </div>
            <div className="mt-10 flex items-center gap-6 text-sm text-white/80">
              <div>
                <div className="text-3xl font-bold text-white">1.5%</div>
                <div>effective cost</div>
              </div>
              <div>
                <div className="text-3xl font-bold text-white">&lt;60s</div>
                <div>quote to confirm</div>
              </div>
              <div>
                <div className="text-3xl font-bold text-white">10+</div>
                <div>destination countries</div>
              </div>
            </div>
          </div>

          {/* Mock phone */}
          <div className="relative mx-auto w-72 rounded-[3rem] border-8 border-slate-900 bg-white p-2 shadow-2xl">
            <div className="rounded-[2.5rem] bg-slate-50 p-5 text-slate-900">
              <div className="text-xs uppercase tracking-wide text-slate-500">You send</div>
              <div className="mt-1 text-3xl font-bold">€200.00</div>
              <hr className="my-4 border-slate-200" />
              <div className="text-xs uppercase tracking-wide text-slate-500">Recipient gets</div>
              <div className="mt-1 flex items-center justify-between">
                <span className="text-2xl font-bold">129 880 XOF</span>
                <span className="text-2xl">🇸🇳</span>
              </div>
              <div className="mt-4 space-y-1 text-xs text-slate-500">
                <div className="flex justify-between"><span>Rate</span><span>649.40</span></div>
                <div className="flex justify-between"><span>Fee</span><span>€1.99</span></div>
                <div className="flex justify-between font-semibold text-slate-900">
                  <span>Total to pay</span><span>€201.99</span>
                </div>
              </div>
              <button className="mt-5 w-full rounded-xl bg-brand py-3 text-sm font-semibold text-white">
                Send now
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="mx-auto max-w-6xl px-6 py-24">
        <h2 className="text-3xl font-bold md:text-4xl">Why wapaExchange</h2>
        <div className="mt-12 grid gap-8 md:grid-cols-3">
          {FEATURES.map((f) => (
            <div key={f.title} className="rounded-2xl border border-slate-100 bg-white p-8 shadow-sm">
              <div className="text-4xl">{f.icon}</div>
              <h3 className="mt-4 text-xl font-semibold">{f.title}</h3>
              <p className="mt-2 text-slate-600">{f.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Corridors */}
      <section id="corridors" className="bg-slate-50 py-24">
        <div className="mx-auto max-w-6xl px-6">
          <h2 className="text-3xl font-bold md:text-4xl">Where we send</h2>
          <p className="mt-3 max-w-xl text-slate-600">
            Mobile money (Orange, MTN, Wave, M-Pesa) + local bank transfers in 10+ countries.
          </p>
          <div className="mt-10 grid gap-4 sm:grid-cols-2 md:grid-cols-3">
            {CORRIDORS.map((c) => (
              <div key={c.name} className="flex items-center gap-4 rounded-xl bg-white p-5 shadow-sm">
                <span className="text-3xl">{c.flag}</span>
                <div>
                  <div className="font-semibold">{c.name}</div>
                  <div className="text-sm text-slate-500">Receive in {c.currency}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Waitlist */}
      <section id="waitlist" className="bg-brand py-24 text-white">
        <div className="mx-auto max-w-2xl px-6 text-center">
          <h2 className="text-3xl font-bold md:text-4xl">Get early access</h2>
          <p className="mt-4 text-white/90">
            We're launching beta in France and Germany. Drop your email to be invited
            to TestFlight when we're ready.
          </p>
          <form className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center" action="https://formspree.io/f/REPLACE-ME" method="POST">
            <input
              type="email"
              name="email"
              required
              placeholder="you@example.com"
              className="flex-1 rounded-full bg-white/10 px-5 py-3 placeholder-white/60 ring-1 ring-white/20 focus:outline-none focus:ring-white"
            />
            <button
              type="submit"
              className="rounded-full bg-white px-6 py-3 font-semibold text-brand hover:bg-slate-100"
            >
              Join waitlist
            </button>
          </form>
        </div>
      </section>

      <footer className="border-t border-slate-100 py-10 text-sm text-slate-500">
        <div className="mx-auto flex max-w-6xl flex-col gap-3 px-6 sm:flex-row sm:items-center sm:justify-between">
          <div>© {new Date().getFullYear()} wapaExchange. Operating as agent of [Licensed PI partner].</div>
          <div className="flex gap-5">
            <Link href="/terms" className="hover:text-slate-800">Terms</Link>
            <Link href="/privacy" className="hover:text-slate-800">Privacy</Link>
            <a href="mailto:hello@wapaexchange.com" className="hover:text-slate-800">Contact</a>
          </div>
        </div>
      </footer>
    </main>
  );
}
