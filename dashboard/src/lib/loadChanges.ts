export type ChangeStatus = 'archived' | 'ready' | 'draft' | 'in-progress';

export interface SpecFile {
  name: string;
  path: string;
  content: string;
}

export interface Change {
  id: string;
  title: string;
  date: string;
  status: ChangeStatus;
  archived: boolean;
  proposal?: string;
  design?: string;
  tasks?: string;
  specs: SpecFile[];
  taskProgress: { done: number; total: number };
}

const rawFiles = import.meta.glob('@openspec/changes/**/*.md', {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string>;

function parseTaskProgress(tasksMd: string | undefined) {
  if (!tasksMd) return { done: 0, total: 0 };
  const lines = tasksMd.split('\n');
  let done = 0, total = 0;
  for (const line of lines) {
    if (/^\s*- \[[ x]\]/i.test(line)) {
      total++;
      if (/^\s*- \[x\]/i.test(line)) done++;
    }
  }
  return { done, total };
}

function extractTitleFromProposal(md: string | undefined, fallback: string): string {
  if (!md) return fallback;
  const m = md.match(/^#\s+(.+)$/m);
  return m ? m[1].trim() : fallback;
}

function inferStatus(id: string, archived: boolean, files: Record<string, string>): ChangeStatus {
  if (archived) return 'archived';
  const has = (suffix: string) =>
    Object.keys(files).some((k) => k.endsWith(`/${id}/${suffix}`));
  if (has('plan-ready.md')) return 'ready';
  return 'draft';
}

export function loadChanges(): Change[] {
  const grouped: Record<string, Record<string, string>> = {};

  for (const [absPath, content] of Object.entries(rawFiles)) {
    const m = absPath.match(/\/changes\/(archive\/)?([^/]+)\/(.+)$/);
    if (!m) continue;
    const [, archivedPrefix, idRaw, rest] = m;
    const id = (archivedPrefix ? 'archive/' : '') + idRaw;
    if (!grouped[id]) grouped[id] = {};
    grouped[id][rest] = content;
  }

  const changes: Change[] = [];
  for (const [id, files] of Object.entries(grouped)) {
    const archived = id.startsWith('archive/');
    const cleanId = archived ? id.slice('archive/'.length) : id;
    const dateMatch = cleanId.match(/^(\d{4}-\d{2}-\d{2})/);
    const date = dateMatch ? dateMatch[1] : '';

    const proposal = files['proposal.md'];
    const design = files['design.md'];
    const tasks = files['tasks.md'];

    const specs: SpecFile[] = [];
    for (const [k, v] of Object.entries(files)) {
      if (k.startsWith('specs/')) {
        specs.push({ name: k.replace(/^specs\//, ''), path: k, content: v });
      }
    }

    changes.push({
      id: cleanId,
      title: extractTitleFromProposal(proposal, cleanId),
      date,
      status: inferStatus(idRaw(id), archived, rawFiles),
      archived,
      proposal,
      design,
      tasks,
      specs,
      taskProgress: parseTaskProgress(tasks),
    });
  }

  return changes.sort((a, b) => b.date.localeCompare(a.date));
}

function idRaw(id: string): string {
  return id.startsWith('archive/') ? id.slice('archive/'.length) : id;
}
