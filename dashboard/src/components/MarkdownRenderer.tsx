import { useEffect, useRef } from 'react';
import mermaid from 'mermaid';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';

mermaid.initialize({ startOnLoad: false, theme: 'default' });

let mermaidCounter = 0;

function MermaidBlock({ code }: { code: string }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const id = `mermaid-${++mermaidCounter}`;
    mermaid.render(id, code).then(({ svg }) => {
      if (ref.current) ref.current.innerHTML = svg;
    }).catch((err) => {
      if (ref.current) ref.current.innerHTML = `<pre style="color:#cf222e">${String(err)}</pre>`;
    });
  }, [code]);
  return <div className="mermaid" ref={ref} />;
}

export default function MarkdownRenderer({ source }: { source: string }) {
  return (
    <div className="markdown-body">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        components={{
          code({ className, children, ...props }) {
            const match = /language-(\w+)/.exec(className || '');
            const text = String(children).replace(/\n$/, '');
            if (match && match[1] === 'mermaid') {
              return <MermaidBlock code={text} />;
            }
            return <code className={className} {...props}>{children}</code>;
          },
        }}
      >
        {source}
      </ReactMarkdown>
    </div>
  );
}
