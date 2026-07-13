import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'wapaExchange — Send money home, fairly',
  description:
    'Mobile-first remittance from Europe to Africa & Asia. Real-time exchange rates, transparent fees, licensed banking partners.',
  openGraph: {
    title: 'wapaExchange — Send money home, fairly',
    description: 'From Europe to Africa & Asia in minutes. Real rates, no hidden fees.',
    url: 'https://wapaexchange.com',
    siteName: 'wapaExchange',
    locale: 'en_US',
    type: 'website',
  },
  themeColor: '#1a6cf2',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
