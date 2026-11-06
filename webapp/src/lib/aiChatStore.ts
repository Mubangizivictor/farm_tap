// Saved chats on this device (decision 0027): the list behind "Chats". Kept in
// the browser only, per farm, never sent anywhere. Pure helpers first so they
// can be tested; the load/save at the bottom never throws.

import type { ChatAction, ChatGrounding, Triage } from '../shared/aiChat.ts';
import type { Method } from '../shared/aiCore.ts';

export interface SavedTurn {
  id: number;
  who: 'me' | 'ai';
  text: string;
  files?: { name: string; kind: string }[];
  method?: Method;
  aboutAnimal?: string;
  saved?: boolean;
  note?: string;
  /** The real reason an online answer failed, for the Details line. */
  detail?: string;
  actions?: ChatAction[];
  followUps?: string[];
  grounding?: ChatGrounding | null;
  /** The question this answer replied to. */
  asked?: string;
  /** Urgency card for a sick-animal answer. */
  triage?: Triage | null;
  /** The animal this answer is about (Firestore id). */
  animalId?: string;
  /** A photo or video was sent with the question. */
  hadMedia?: boolean;
  /** Which model answered. */
  model?: string;
  /** Which layer answered (decision 0028): records and insight are calculated, ai is a model. */
  layer?: 'records' | 'insight' | 'ai';
  /** Why the AI did not answer (shown as a card above the built-in answer). */
  errorKind?: 'limit' | 'unavailable' | 'network' | 'timeout' | 'disabled' | 'invalid' | 'capacity' | 'tooFast';
  /** The farmer's thumbs up or down on this answer. */
  vote?: 'up' | 'down';
}

export interface SavedChat {
  id: string;
  title: string;
  updatedAt: number;
  turns: SavedTurn[];
}

export const MAX_CHATS = 40;
export const MAX_TURNS = 60;

/** Newest first, the open chat added or replaced, oldest dropped past the limit. */
export function upsertChat(list: SavedChat[], chat: SavedChat): SavedChat[] {
  const rest = list.filter((c) => c.id !== chat.id);
  return [{ ...chat, turns: chat.turns.slice(-MAX_TURNS) }, ...rest].sort((a, b) => b.updatedAt - a.updatedAt).slice(0, MAX_CHATS);
}

/** Chats whose title or any message contains every word typed. */
export function searchChats(list: SavedChat[], query: string): SavedChat[] {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  if (!words.length) return list;
  return list.filter((c) => {
    const hay = `${c.title}\n${c.turns.map((t) => t.text).join('\n')}`.toLowerCase();
    return words.every((w) => hay.includes(w));
  });
}

/** "Today", "Yesterday", "Last 7 days" or "Older" for a chat's last change. */
export function chatGroup(updatedAt: number, now: number): string {
  const d = new Date(now);
  const start = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  const day = 86_400_000;
  if (updatedAt >= start) return 'Today';
  if (updatedAt >= start - day) return 'Yesterday';
  if (updatedAt >= start - 6 * day) return 'Last 7 days';
  return 'Older';
}

export function groupChats(list: SavedChat[], now: number): { label: string; chats: SavedChat[] }[] {
  const order = ['Today', 'Yesterday', 'Last 7 days', 'Older'];
  return order.map((label) => ({ label, chats: list.filter((c) => chatGroup(c.updatedAt, now) === label) })).filter((g) => g.chats.length);
}

const key = (farmId: string) => `farmtap.ai.chats.${farmId}`;

export function loadChats(farmId: string): SavedChat[] {
  try {
    const raw = window.localStorage.getItem(key(farmId));
    const list = raw ? (JSON.parse(raw) as SavedChat[]) : [];
    return Array.isArray(list) ? list.filter((c) => c && typeof c.id === 'string' && Array.isArray(c.turns)) : [];
  } catch {
    return [];
  }
}

export function storeChats(farmId: string, list: SavedChat[]): void {
  try {
    window.localStorage.setItem(key(farmId), JSON.stringify(list));
  } catch {
    /* private window or full: chats are just not kept */
  }
}
