import { createGetUrl } from 'fumadocs-core/source';

export const appName = 'omarchy4mac';
export const docsRoute = '/docs';
export const docsImageRoute = '/og/docs';
export const docsContentRoute = '/llms.mdx/docs';

// The repo the pages link back to, and the path of the content inside it.
export const gitConfig = {
  user: 'dividendsolo',
  repo: 'omarchy4mac',
  branch: 'main',
  contentDir: 'docs-site/content/docs',
};

const getContentUrl = createGetUrl(docsContentRoute);

export function getPageMarkdownUrl(page: { slugs: string[]; locale?: string }) {
  const segments = [...page.slugs, 'content.md'];

  return { segments, url: getContentUrl(segments, page.locale) };
}

const getImageUrl = createGetUrl(docsImageRoute);

export function getPageImageUrl(page: { slugs: string[]; locale?: string }) {
  const segments = [...page.slugs, 'image.png'];

  return { segments, url: getImageUrl(segments, page.locale) };
}
