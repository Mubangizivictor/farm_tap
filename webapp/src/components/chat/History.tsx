'use client';

// "Your chats" (decision 0027): a drawer with search, filters by topic, pinned chats first, and
// the colour of the worst urgency seen in each chat. Kept on this device only.

import { useMemo, useState } from 'react';
import { Icon, type IconName } from '@/components/Icon';
import { groupChats, searchChats, type SavedChat } from '@/lib/aiChatStore';
import type { ChatCategory } from '@/shared/aiChat';

export const CAT: Record<ChatCategory, { label: string; icon: IconName; tone: string }> = {
  health: { label: 'Health', icon: 'health', tone: 'bad' },
  photos: { label: 'Photos', icon: 'image', tone: 'blue' },
  milk: { label: 'Milk', icon: 'milk', tone: 'pri' },
  money: { label: 'Money', icon: 'money', tone: 'warn' },
  breeding: { label: 'Breeding', icon: 'cow', tone: 'ok' },
  feed: { label: 'Feed', icon: 'feed', tone: 'gold' },
  other: { label: 'Other', icon: 'chat', tone: 'pri' },
};

export function History({ chats, openId, onOpen, onNew, onPin, onDelete, onClose }: { chats: SavedChat[]; openId: string; onOpen: (c: SavedChat) => void; onNew: () => void; onPin: (id: string) => void; onDelete: (id: string) => void; onClose: () => void }) {
  const [find, setFind] = useState('');
  const [cat, setCat] = useState<ChatCategory | 'all'>('all');
  const shown = useMemo(() => searchChats(chats, find).filter((c) => cat === 'all' || (c.cat ?? 'other') === cat), [chats, find, cat]);
  const used = useMemo(() => [...new Set(chats.map((c) => c.cat ?? 'other'))], [chats]);
  return (
    <>
      <button className="ct-under" aria-label="Close your chats" onClick={onClose} />
      <aside className="ct-drawer" aria-label="Your chats">
        <div className="dh">
          <h2>Your chats</h2>
          <button className="ct-btn fill sm" onClick={onNew}><Icon name="edit" /> New chat</button>
          <button className="ct-ib" aria-label="Close" onClick={onClose}><Icon name="close" /></button>
        </div>
        <label className="ct-searchbox">
          <Icon name="search" />
          <input type="search" placeholder="Search your chats" aria-label="Search your chats" value={find} onChange={(e) => setFind(e.target.value)} />
        </label>
        {used.length > 1 && (
          <div className="ct-filters">
            {(['all', ...used] as const).map((k) => (
              <button key={k} className={`ct-chip${cat === k ? ' pri' : ' line'}`} aria-pressed={cat === k} onClick={() => setCat(k)}>
                {k === 'all' ? 'All' : CAT[k].label}
              </button>
            ))}
          </div>
        )}
        <div className="dlist">
          {groupChats(shown, Date.now()).map((g) => (
            <div key={g.label}>
              <div className="dg">{g.label === 'Pinned' && <Icon name="pinFill" />} {g.label}</div>
              {g.chats.map((c) => {
                const k = CAT[c.cat ?? 'other'];
                const last = [...c.turns].reverse().find((t) => t.who === 'ai')?.text ?? '';
                return (
                  <div key={c.id} className={`ct-ci${c.id === openId ? ' sel' : ''}`}>
                    <button className="open" onClick={() => onOpen(c)}>
                      <span className={`ico t-${k.tone}`}>
                        <Icon name={k.icon} />
                        {c.urg && <i className={`u-${c.urg}`} aria-label={c.urg === 'now' ? 'Emergency' : c.urg === 'today' ? 'Urgent' : 'Watch'} />}
                      </span>
                      <span className="txt">
                        <b>{c.title}</b>
                        <span className="s">{c.cow ? `${c.cow} · ` : ''}{last.replace(/[*#]/g, '').replace(/\s+/g, ' ').slice(0, 70)}</span>
                      </span>
                    </button>
                    <span className="acts">
                      <button className="ct-ib sm" aria-label={c.pinned ? `Unpin ${c.title}` : `Pin ${c.title}`} title={c.pinned ? 'Unpin' : 'Pin'} onClick={() => onPin(c.id)}><Icon name={c.pinned ? 'pinFill' : 'pin'} /></button>
                      <button className="ct-ib sm" aria-label={`Delete ${c.title}`} title="Delete" onClick={() => onDelete(c.id)}><Icon name="trash" /></button>
                    </span>
                  </div>
                );
              })}
            </div>
          ))}
          {!shown.length && <p className="small muted ct-none">{chats.length ? 'No chat matches that.' : 'Your chats will show here.'}</p>}
        </div>
        <div className="dfoot"><Icon name="lock" /> Kept on this phone or computer only.</div>
      </aside>
    </>
  );
}
