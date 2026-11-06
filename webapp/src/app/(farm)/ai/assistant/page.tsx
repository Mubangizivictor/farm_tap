'use client';

// AI Farm Assistant (decision 0025): questions answered from the farm's
// own records. Conversation history is kept in this browser tab only.

import Link from 'next/link';
import { useEffect, useRef, useState } from 'react';
import { Icon } from '@/components/Icon';
import { MethodBadge, ModuleHead } from '@/components/ai';
import { AiGate, useAiPage } from '@/components/aiPage';
import { ask, suggestedQuestions, type Answer } from '@/shared/aiAssistant';
import { seesMoney } from '@/shared/aiAccess';
import { logAi } from '@/lib/ai';

interface Turn {
  id: number;
  q: string;
  a: Answer;
  at: string;
}

const KEY = 'farmtap.ai.chat';

export default function Assistant() {
  const page = useAiPage('assistant');
  const { farm, cfg, ai } = page;
  const [q, setQ] = useState('');
  const [turns, setTurns] = useState<Turn[]>([]);
  const end = useRef<HTMLDivElement>(null);

  useEffect(() => {
    try {
      const raw = window.sessionStorage.getItem(`${KEY}.${farm.id}`);
      if (raw) setTurns(JSON.parse(raw) as Turn[]);
    } catch {
      /* private window: start empty */
    }
  }, [farm.id]);
  useEffect(() => {
    try {
      window.sessionStorage.setItem(`${KEY}.${farm.id}`, JSON.stringify(turns.slice(-30)));
    } catch {
      /* not kept */
    }
    end.current?.scrollIntoView({ block: 'end', behavior: 'smooth' });
  }, [turns, farm.id]);

  const send = (text: string) => {
    const question = text.trim();
    if (!question || ai.loading) return;
    const t0 = performance.now();
    const a = ask(question, ai.data, { role: farm.role, cfg: cfg.ai, farmAiOn: true });
    logAi(farm.id, 'assistant', a.ok, performance.now() - t0, a.method);
    setTurns((ts) => [...ts, { id: Date.now(), q: question, a, at: new Date().toISOString() }]);
    setQ('');
  };

  const suggestions = suggestedQuestions.filter((s) => seesMoney(farm.role) || !/spend|expensive|cost/i.test(s));

  return (
    <>
      <ModuleHead module="assistant" title="Farm Assistant" subtitle="Ask about your milk, animals, feed and money. Answers come from your own records.">
        {turns.length > 0 && (
          <button className="btn sm ghost" onClick={() => setTurns([])}>
            <Icon name="refresh" /> New conversation
          </button>
        )}
      </ModuleHead>
      <AiGate page={page}>
        <div className="ai-chat" aria-live="polite">
          {turns.length === 0 && (
            <div className="card stack">
              <p className="muted">Try one of these, or type your own question.</p>
              <div className="chips">
                {suggestions.map((s) => (
                  <button key={s} type="button" className="chip" onClick={() => send(s)}>
                    {s}
                  </button>
                ))}
              </div>
            </div>
          )}
          {turns.map((t) => (
            <div key={t.id} className="stack" style={{ gap: 'var(--s-md)' }}>
              <div className="ai-msg me">
                <p>{t.q}</p>
              </div>
              <div className="ai-msg" role="article">
                <p>
                  <strong>{t.a.text}</strong>
                </p>
                {t.a.bullets.length > 0 && (
                  <ul>
                    {t.a.bullets.map((b, i) => (
                      <li key={i}>{b}</li>
                    ))}
                  </ul>
                )}
                <div className="row wrap">
                  {t.a.links.map((l) => (
                    <Link key={l.href + l.label} className="btn sm outline" href={l.href}>
                      {l.label} <Icon name="chevron" />
                    </Link>
                  ))}
                </div>
                <div className="row wrap">
                  <MethodBadge method={t.a.method} />
                </div>
              </div>
            </div>
          ))}
          <div ref={end} />
        </div>
        <form
          className="ai-ask"
          onSubmit={(e) => {
            e.preventDefault();
            send(q);
          }}
        >
          <input className="input" value={q} onChange={(e) => setQ(e.target.value)} placeholder="Ask about your farm…" aria-label="Your question" maxLength={300} />
          <button className="btn" type="submit" disabled={!q.trim()}>
            <Icon name="chat" /> Ask
          </button>
        </form>
        <p className="small muted">
          FarmTap only answers what it can work out exactly from your records. If it cannot, it says so. It never sends your records to an AI company.
        </p>
      </AiGate>
    </>
  );
}
