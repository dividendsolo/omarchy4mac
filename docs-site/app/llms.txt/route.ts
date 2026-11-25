import { docsLlms } from '@/lib/source';
import { skillLlmsEntry } from '@/lib/skill';

export const revalidate = false;

export async function GET() {
  const index = await docsLlms.index();
  return new Response(`${index.trimEnd()}\n${skillLlmsEntry}\n`);
}
