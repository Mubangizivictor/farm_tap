// Plain-text answers shown the way a chat shows them: paragraphs, lists and
// **bold**. Never HTML: whatever the model sends is shown as text.

import type { ReactNode } from 'react';

function inline(t: string): ReactNode[] {
  return t.split(/(\*\*[^*]+\*\*)/g).map((p, i) => (p.startsWith('**') && p.endsWith('**') && p.length > 4 ? <strong key={i}>{p.slice(2, -2)}</strong> : p));
}

/** A closing "call the vet" style line: shown as a callout so it is not missed. */
const CALLOUT = /^(if|when|call|see|get|contact|tell|report)\b.*\b(vet|veterinar|dvo)\b/i;

export function ChatText({ text, streaming = false }: { text: string; streaming?: boolean }) {
  const blocks: ReactNode[] = [];
  let list: { ordered: boolean; items: string[] } | null = null;
  const flush = () => {
    if (!list) return;
    const items = list.items.map((x, i) => <li key={i}>{inline(x)}</li>);
    blocks.push(list.ordered ? <ol key={blocks.length} className="chat-points">{items}</ol> : <ul key={blocks.length} className="chat-points">{items}</ul>);
    list = null;
  };
  for (const raw of text.split('\n')) {
    const line = raw.trim();
    const bullet = /^[-*•]\s+(.*)$/.exec(line);
    const num = /^\d+[.)]\s+(.*)$/.exec(line);
    if (bullet || num) {
      const ordered = !!num;
      if (!list || list.ordered !== ordered) {
        flush();
        list = { ordered, items: [] };
      }
      list.items.push((bullet ?? num)![1]);
      continue;
    }
    flush();
    if (!line) continue;
    const head = /^#{1,4}\s+(.*)$/.exec(line);
    const key = blocks.length;
    if (head) blocks.push(<p key={key} className="chat-label">{inline(head[1])}</p>);
    else if (line.length <= 48 && line.endsWith(':')) blocks.push(<p key={key} className="chat-label">{inline(line.slice(0, -1))}</p>);
    else if (key > 0 && CALLOUT.test(line.replace(/\*\*/g, ''))) blocks.push(<p key={key} className="chat-callout">{inline(line)}</p>);
    else blocks.push(<p key={key} className={key === 0 ? 'chat-lead' : undefined}>{inline(line)}</p>);
  }
  flush();
  return <div className={`chat-text${streaming ? ' streaming' : ''}`}>{blocks}</div>;
}
