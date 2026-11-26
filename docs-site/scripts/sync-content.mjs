import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const appDir = join(here, '..');
const repo = join(appDir, '..');
const check = process.argv.includes('--check');

const pages = [
  {
    from: join(repo, 'CHANGELOG.md'),
    to: join(appDir, 'content/docs/changelog.md'),
    note: 'This page is generated from [CHANGELOG.md](https://github.com/dividendsolo/omarchy4mac/blob/main/CHANGELOG.md). Edit that file, then run `npm run sync-content`.',
    description: 'Every change to omarchy4mac, newest first, from the install script to the theme pipeline.',
  },
  {
    from: join(repo, 'docs/parity-v4.md'),
    to: join(appDir, 'content/docs/parity-checklist.md'),
    note: 'This page is generated from [docs/parity-v4.md](https://github.com/dividendsolo/omarchy4mac/blob/main/docs/parity-v4.md). Edit that file, then run `npm run sync-content`.',
    description:
      'Every item in the scorecard, ticked or not: the keybindings, the workspace model, the theme pipeline, and what the Mac cannot do.',
  },
];

let drifted = 0;

for (const { from, to, note, description } of pages) {
  const body = await readFile(from, 'utf8');
  const title = body.match(/^#\s+(.*)$/m)?.[1]?.trim();
  if (!title) throw new Error(`${from} has no h1 to use as the page title`);
  const source = body.replace(/^#\s+.*\n+/, '');
  const page = `---\ntitle: ${JSON.stringify(title)}\ndescription: ${JSON.stringify(description)}\n---\n\n_${note}_\n\n${source}`;
  const where = relative(repo, to);

  if (!check) {
    await mkdir(dirname(to), { recursive: true });
    await writeFile(to, page);
    console.log(`sync-content: ${relative(repo, from)} -> ${where} ("${title}")`);
    continue;
  }

  const current = await readFile(to, 'utf8').catch(() => null);
  if (current === page) {
    console.log(`  ok    ${where} matches ${relative(repo, from)}`);
    continue;
  }
  drifted += 1;
  console.log(`  FAIL  ${where} does not match ${relative(repo, from)}; run: npm run sync-content`);
  if (current !== null) {
    const want = page.split('\n');
    const have = current.split('\n');
    for (let i = 0; i < Math.max(want.length, have.length); i++) {
      if (want[i] !== have[i]) {
        console.log(`        first difference on line ${i + 1}:`);
        console.log(`          the repo says: ${JSON.stringify(want[i] ?? '(end of file)')}`);
        console.log(`          the page has:  ${JSON.stringify(have[i] ?? '(end of file)')}`);
        break;
      }
    }
  }
}

if (check && drifted) process.exit(1);
