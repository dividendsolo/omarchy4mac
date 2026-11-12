import { createMDX } from 'fumadocs-mdx/next';

const withMDX = createMDX();

/** @type {import('next').NextConfig} */
const config = {
  reactStrictMode: true,
  // The docs are the site: no front page (#73).
  async redirects() {
    return [{ source: '/', destination: '/docs', permanent: false }];
  },
};

export default withMDX(config);
