import { useMemo, useState } from 'react';
import { loadChanges, type Change } from './lib/loadChanges';
import MarkdownRenderer from './components/MarkdownRenderer';

const STATUS_LABEL: Record<string, string> = {
  archived: '已归档',
  ready: '待启动',
  draft: '草稿',
  'in-progress': '进行中',
};

export default function App() {
  const changes = useMemo(() => loadChanges(), []);
  const [selectedId, setSelectedId] = useState<string | null>(changes[0]?.id ?? null);
  const [keyword, setKeyword] = useState('');
  const [tab, setTab] = useState<'proposal' | 'design' | 'tasks' | 'specs'>('proposal');
  const [activeSpec, setActiveSpec] = useState(0);

  const filtered = changes.filter((c) =>
    !keyword ||
    c.title.toLowerCase().includes(keyword.toLowerCase()) ||
    c.id.toLowerCase().includes(keyword.toLowerCase())
  );

  const current = changes.find((c) => c.id === selectedId);

  const handleSelect = (c: Change) => {
    setSelectedId(c.id);
    setActiveSpec(0);
    setTab(c.proposal ? 'proposal' : c.design ? 'design' : c.tasks ? 'tasks' : 'specs');
  };

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="sidebar-header">
          <h1>SDD Workspace ({changes.length})</h1>
          <input
            placeholder="搜索变更..."
            value={keyword}
            onChange={(e) => setKeyword(e.target.value)}
          />
        </div>
        {filtered.map((c) => (
          <div
            key={c.id}
            className={`change-item ${c.id === selectedId ? 'active' : ''}`}
            onClick={() => handleSelect(c)}
          >
            <div className="change-title">{c.title}</div>
            <div className="change-meta">
              <span className={`badge ${c.status}`}>{STATUS_LABEL[c.status]}</span>
              <span>{c.date}</span>
              {c.taskProgress.total > 0 && (
                <span>
                  {c.taskProgress.done}/{c.taskProgress.total}
                </span>
              )}
            </div>
            {c.taskProgress.total > 0 && (
              <div className="progress">
                <div
                  className="progress-bar"
                  style={{ width: `${(c.taskProgress.done / c.taskProgress.total) * 100}%` }}
                />
              </div>
            )}
          </div>
        ))}
      </aside>

      <main className="detail">
        {!current && <div className="detail-empty">选择左侧需求查看详情</div>}
        {current && (
          <>
            <div className="detail-header">
              <h2>{current.title}</h2>
              <div className="change-meta">
                <span className={`badge ${current.status}`}>{STATUS_LABEL[current.status]}</span>
                <span>{current.id}</span>
              </div>
              <div className="detail-tabs">
                {current.proposal && (
                  <button className={`tab ${tab === 'proposal' ? 'active' : ''}`} onClick={() => setTab('proposal')}>
                    Proposal
                  </button>
                )}
                {current.design && (
                  <button className={`tab ${tab === 'design' ? 'active' : ''}`} onClick={() => setTab('design')}>
                    Design
                  </button>
                )}
                {current.tasks && (
                  <button className={`tab ${tab === 'tasks' ? 'active' : ''}`} onClick={() => setTab('tasks')}>
                    Tasks
                    <span className="count">
                      {current.taskProgress.done}/{current.taskProgress.total}
                    </span>
                  </button>
                )}
                {current.specs.length > 0 && (
                  <button className={`tab ${tab === 'specs' ? 'active' : ''}`} onClick={() => setTab('specs')}>
                    Specs<span className="count">{current.specs.length}</span>
                  </button>
                )}
              </div>
            </div>

            {tab === 'proposal' && current.proposal && <MarkdownRenderer source={current.proposal} />}
            {tab === 'design' && current.design && <MarkdownRenderer source={current.design} />}
            {tab === 'tasks' && current.tasks && <MarkdownRenderer source={current.tasks} />}
            {tab === 'specs' && current.specs.length > 0 && (
              <>
                <div style={{ padding: '12px 32px 0', display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  {current.specs.map((s, i) => (
                    <button
                      key={s.path}
                      className={`tab ${i === activeSpec ? 'active' : ''}`}
                      onClick={() => setActiveSpec(i)}
                    >
                      {s.name}
                    </button>
                  ))}
                </div>
                <MarkdownRenderer source={current.specs[activeSpec]?.content ?? ''} />
              </>
            )}
          </>
        )}
      </main>
    </div>
  );
}
