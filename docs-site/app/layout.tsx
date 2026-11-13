import { RootProvider } from 'fumadocs-ui/provider/next';
import './global.css';
import { Inter } from 'next/font/google';
import type { Metadata } from 'next';

const inter = Inter({
  subsets: ['latin'],
});

// The deployed address, for the Open Graph images. Vercel sets
// VERCEL_PROJECT_PRODUCTION_URL; NEXT_PUBLIC_SITE_URL overrides it for a
// custom domain.
const siteUrl = process.env.NEXT_PUBLIC_SITE_URL
  ? process.env.NEXT_PUBLIC_SITE_URL
  : process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : 'http://localhost:3000';

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: 'omarchy4mac',
    template: '%s · omarchy4mac',
  },
  description:
    "Omarchy 4's desktop on the Mac: AeroSpace for tiling, SketchyBar for the bar, and one theme script that themes everything.",
};

export default function Layout({ children }: LayoutProps<'/'>) {
  return (
    <html lang="en" className={inter.className} suppressHydrationWarning>
      <body className="flex flex-col min-h-screen">
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}
