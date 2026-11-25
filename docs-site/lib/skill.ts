import { readFileSync } from 'node:fs';
import { join } from 'node:path';

export const skillPath = '/SKILL.md';

const frontmatter = /^---\n([\s\S]*?)\n---\n/;
const source = () => readFileSync(join(process.cwd(), 'public', skillPath.slice(1)), 'utf8');

const field = (name: string) => {
  const block = frontmatter.exec(source())?.[1];
  if (!block) throw new Error(`${skillPath} has no frontmatter`);
  const value = new RegExp(`^${name}:\\s*(.+)$`, 'm').exec(block)?.[1];
  if (!value) throw new Error(`${skillPath} has no ${name}`);
  return value.trim();
};

export const skillDescription = field('description');

export const skillLlmsEntry = `- [Agent skill](${skillPath}): ${skillDescription}`;
