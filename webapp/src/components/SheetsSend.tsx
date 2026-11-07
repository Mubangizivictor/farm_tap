'use client';

// "Send to Google Sheets" (lib/sheets.ts). Shows what was sent, or why it failed, in plain words.
import { useEffect, useRef, useState } from 'react';
import { Icon } from '@/components/Icon';
import { useAdmin } from '@/lib/adminSession';
import { lastSent, sendToSheets, sheetsDue, sheetsUrlOk, type SheetsSettings } from '@/lib/sheets';
import { useSession } from '@/lib/session';

export function SheetsSendButton({ settings, disabled, auto }: { settings: SheetsSettings; disabled?: boolean; auto?: boolean }) {
  const { can, me } = useAdmin();
  const { user } = useSession();
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null);
  const [when, setWhen] = useState<Date | null>(null);
  const tried = useRef(false);
  const ready = sheetsUrlOk(settings.url) && !!settings.secret;
  const by = me?.name || user?.email || '';

  const send = async (quiet = false) => {
    if (!ready || busy) return;
    setBusy(true);
    if (!quiet) setMsg(null);
    try {
      const tabs = await sendToSheets(settings, can, by);
      setMsg({ ok: true, text: `Sent to Google Sheets: ${tabs.join(', ')}.` });
      setWhen(lastSent());
    } catch (e) {
      if (!quiet) setMsg({ ok: false, text: (e as Error).message });
    } finally {
      setBusy(false);
    }
  };

  useEffect(() => {
    setWhen(lastSent());
    if (auto && settings.auto && ready && !tried.current && sheetsDue()) {
      tried.current = true;
      void send(true);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [auto, settings.auto, ready]);

  if (!ready) return null;
  return (
    <div className="stack" style={{ gap: 'var(--s-xs)' }}>
      <div className="row wrap">
        <button className="btn outline sm" disabled={busy || disabled} onClick={() => void send()} title="Copy Farms, Payments, Users and the Audit log to your Google Sheet">
          {busy ? <span className="spinner sm" aria-hidden /> : <Icon name="export" />} <span className="btn-text">{busy ? 'Sending…' : 'Send to Google Sheets'}</span>
        </button>
        {when && <span className="small muted">Last sent from this browser: {when.toLocaleString('en-GB', { dateStyle: 'medium', timeStyle: 'short' })}</span>}
      </div>
      {msg && <small className={msg.ok ? 'muted' : 'error-text'}>{msg.text}</small>}
    </div>
  );
}
