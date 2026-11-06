// Copy a whole chat as text, and print a one-page report for the vet (decision 0027). Both use
// only what is already on the screen; nothing is sent anywhere.

import type { SavedChat } from './aiChatStore.ts';

export function chatAsText(chat: SavedChat): string {
  const lines = [chat.title, ''];
  for (const t of chat.turns) {
    if (!t.text) continue;
    lines.push(`${t.who === 'me' ? 'Me' : 'FarmTap AI'}: ${t.text}`, '');
  }
  return lines.join('\n').trim();
}

const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c] ?? c);

/** Plain HTML for a printable vet report: the message for the vet, nothing else. */
export function reportHtml(title: string, message: string): string {
  return `<!doctype html><meta charset="utf-8"><title>${esc(title)}</title><body><h1>${esc(title)}</h1><pre style="white-space:pre-wrap">${esc(message)}</pre>`;
}

/** Opens the report in a new tab and prints it. Returns false when the browser blocked the tab. */
export function printReport(title: string, message: string): boolean {
  const w = window.open('', '_blank');
  if (!w) return false;
  w.document.write(reportHtml(title, message));
  w.document.close();
  w.focus();
  w.print();
  return true;
}
