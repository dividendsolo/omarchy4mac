import { access, readFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const site = join(here, '..');
const out = join(site, 'out');
const origin = 'https://omarchy4mac.dividendsolo.com';

const exists = async (path) => {
  try {
    await access(path);
    return true;
  } catch {
    return false;
  }
};

const meta = JSON.parse(await readFile(join(site, 'content', 'docs', 'meta.json'), 'utf8'));
const paths = meta.pages.map((name) => (name === 'index' ? '/docs' : `/docs/${name}`));

const sitemap = await readFile(join(out, 'sitemap.xml'), 'utf8');
const robots = await readFile(join(out, 'robots.txt'), 'utf8');
const listed = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map((match) => match[1]);

const problems = [];

for (const path of paths) {
  const url = `${origin}${path}`;
  if (!listed.includes(url)) problems.push(`${url} is not in out/sitemap.xml`);
  const page = join(out, path.slice(1));
  const built = (await exists(`${page}.html`)) || (await exists(join(page, 'index.html')));
  if (!built) problems.push(`${url} has no built page in out/`);
}

for (const url of listed) {
  if (!url.startsWith(`${origin}/`)) problems.push(`${url} is not an address on ${origin}`);
}

if (!listed.length) problems.push('out/sitemap.xml lists no page at all');
if (!robots.includes(`Sitemap: ${origin}/sitemap.xml`)) {
  problems.push(`out/robots.txt does not name ${origin}/sitemap.xml`);
}
if (!/^Allow: \/$/m.test(robots)) problems.push('out/robots.txt does not allow crawling');
if (/^Disallow: \/$/m.test(robots)) problems.push('out/robots.txt blocks every crawler');

console.log(`seo: ${listed.length} pages in the sitemap, ${paths.length} in the sidebar`);
for (const url of listed) console.log(`  ${url}`);

if (problems.length) {
  for (const problem of problems) console.log(`  FAIL  ${problem}`);
  console.log(`FAIL: ${problems.length} problem(s)`);
  process.exit(1);
}
console.log('PASS');
