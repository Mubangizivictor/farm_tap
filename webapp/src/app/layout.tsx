import type { Metadata, Viewport } from 'next';
import type { ReactNode } from 'react';
import { SessionProvider, themeBootScript } from '@/lib/session';
import '@/theme/tokens.css';
import '@/styles/app.css';

export const metadata: Metadata = {
  title: 'FarmTap',
  description: 'Farm and milk-collection records for your farm, on any computer.',
  icons: { icon: '/brand/farmtap_app_icon.svg' },
};

export const viewport: Viewport = { width: 'device-width', initialScale: 1 };

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeBootScript }} />
      </head>
      <body>
        <SessionProvider>{children}</SessionProvider>
      </body>
    </html>
  );
}
