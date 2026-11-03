import type { NextConfig } from 'next';

// Static site (decision 0015): hosted free on Firebase Hosting, which also
// serves /__/auth/handler on our own domain for Google/Apple sign-in.
const config: NextConfig = {
  output: 'export',
  trailingSlash: true,
  images: { unoptimized: true },
  reactStrictMode: true,
  devIndicators: false,
};

export default config;
