'use client';

// The first screen of a new chat (decision 0027): a greeting, today's numbers from the farm's own
// records, and ready-made questions. Each card sends a question; nothing is typed.

import type { ReactNode } from 'react';
import { Icon, type IconName } from '@/components/Icon';
import type { FarmToday } from '@/shared/aiToday';

interface Prompt {
  q: string;
  title: string;
  hint: string;
  icon: IconName;
  tone: 'pri' | 'gold' | 'blue' | 'bad' | 'ok' | 'warn';
}

export const PROMPTS: Prompt[] = [
  { q: 'My cow has a swollen udder', title: 'A cow looks unwell', hint: 'Describe it or add a photo', icon: 'health', tone: 'bad' },
  { q: 'Why is our milk dropping?', title: 'Why is milk dropping?', hint: 'Checks your records', icon: 'trend', tone: 'blue' },
  { q: 'How much milk did we collect this week?', title: 'Milk this week', hint: 'From your milk records', icon: 'milk', tone: 'pri' },
  { q: 'What should I feed when milk drops?', title: 'Feed and nutrition', hint: 'Simple, local advice', icon: 'feed', tone: 'gold' },
  { q: 'How do I stop mastitis?', title: 'Prevent mastitis', hint: 'Steps for every milking', icon: 'shield', tone: 'ok' },
  { q: 'Explain our money this month', title: 'Money this month', hint: 'Income, costs, what is left', icon: 'money', tone: 'warn' },
];

export function Welcome({ today, name, onAsk, onPhoto, onVoice, canVoice, usage }: { usage?: ReactNode; today: FarmToday | null; name: string; onAsk: (q: string) => void; onPhoto: () => void; onVoice: () => void; canVoice: boolean }) {
  const hour = new Date().getHours();
  const greet = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
  const m = today?.milk;
  return (
    <div className="ct-hero">
      <span className="ct-orb" aria-hidden>
        <Icon name="spark" />
      </span>
      <h2>
        {greet}
        {name ? `, ${name}` : ''}
      </h2>
      <p className="muted">Ask about a sick animal, milk, feed or money. Add a photo or talk, and I will help.</p>
      {usage && <div className="ct-usage">{usage}</div>}
      {today && (m || today.withdrawal > 0 || today.vaccine) && (
        <div className="ct-today">
          {m && (
            <button className="ct-tcard" onClick={() => onAsk(m.day === 'today' ? 'How is milk today compared with other days?' : 'How was milk yesterday compared with other days?')}>
              <span className="k"><Icon name="milk" /> Milk {m.day}</span>
              <span className="v">
                {m.litres} L
                {m.changePct != null && <small className={m.changePct < 0 ? 'down' : 'up'}>{m.changePct > 0 ? '+' : ''}{m.changePct}%</small>}
              </span>
              <span className="go">Ask about it <Icon name="chevron" /></span>
            </button>
          )}
          <button className="ct-tcard" onClick={() => onAsk('Which animals have milk that cannot be sold right now?')}>
            <span className="k"><Icon name="alert" /> Milk on hold</span>
            <span className="v">{today.withdrawal} {today.withdrawal === 1 ? 'cow' : 'cows'}</span>
            <span className="go">See which <Icon name="chevron" /></span>
          </button>
          {today.vaccine && (
            <button className="ct-tcard" onClick={() => onAsk(`When is the ${today.vaccine!.name} vaccine due?`)}>
              <span className="k"><Icon name="shield" /> Next vaccine</span>
              <span className="v">
                {today.vaccine.name}
                <small className={today.vaccine.days < 0 ? 'down' : ''}>{today.vaccine.days < 0 ? `${-today.vaccine.days}d late` : today.vaccine.days === 0 ? 'today' : `in ${today.vaccine.days}d`}</small>
              </span>
              <span className="go">Plan it <Icon name="chevron" /></span>
            </button>
          )}
        </div>
      )}
      <div className="ct-sect">Try asking</div>
      <div className="ct-prompts">
        {PROMPTS.map((p) => (
          <button key={p.q} className="ct-pr" onClick={() => onAsk(p.q)}>
            <span className={`ico t-${p.tone}`}><Icon name={p.icon} /></span>
            <span>
              <b>{p.title}</b>
              <span className="d">{p.hint}</span>
            </span>
          </button>
        ))}
      </div>
      <div className="ct-modes">
        <button className="ct-chip line" onClick={onPhoto}><Icon name="camera" /> Check a photo</button>
        {canVoice && <button className="ct-chip line" onClick={onVoice}><Icon name="mic" /> Ask by voice</button>}
      </div>
    </div>
  );
}
