import type { NextConfig } from 'next';

// Build number for "please refresh" (decision 0020): the control panel can
// ask every browser on an older build to reload. yyyymmddhhmm, UTC.
const build = new Date().toISOString().replace(/\D/g, '').slice(0, 12);

// Static site (decision 0015): hosted free on Firebase Hosting, which also
// serves /__/auth/handler on our own domain for Google/Apple sign-in.
const config: NextConfig = {
  output: 'export',
  trailingSlash: true,
  images: { unoptimized: true },
  reactStrictMode: true,
  devIndicators: false,
  env: { NEXT_PUBLIC_WEB_BUILD: build },
};

export default config;
