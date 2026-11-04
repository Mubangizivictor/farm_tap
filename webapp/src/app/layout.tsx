import type { Metadata, Viewport } from 'next';
import type { ReactNode } from 'react';
import { SessionProvider, themeBootScript } from '@/lib/session';
import '@/theme/tokens.css';
import '@/styles/app.css';
import '@/styles/public.css';

export const metadata: Metadata = {
  title: 'FarmTap',
  description: 'FarmTap: farm and milk-collection records for Uganda, on your phone (even offline) and on the web. 14 days free.',
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
