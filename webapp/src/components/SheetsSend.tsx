'use client';

// "Send to Google Sheets" (lib/sheets.ts) and the background sync that keeps the
// sheet up to date: right after any change made in the panel, and when the panel
// opens (at most every 10 minutes). Errors are shown in plain words.
import { useCallback, useEffect, useRef, useState } from 'react';
import { Icon } from '@/components/Icon';
import { loadIntegrations } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { lastSent, sendToSheets, sheetsDue, sheetsUrlOk, type SheetsSettings } from '@/lib/sheets';
import { useSession } from '@/lib/session';

/** Tells every Send button on the page that a send finished (button text, last-sent time). */
const SENT = 'farmtap:sheets-sent';

export function SheetsSendButton({ settings, disabled }: { settings: SheetsSettings; disabled?: boolean }) {
  const { can, me } = useAdmin();
  const { user } = useSession();
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null);
  const [when, setWhen] = useState<Date | null>(null);
  const ready = sheetsUrlOk(settings.url) && !!settings.secret;

  useEffect(() => {
    setWhen(lastSent());
    const update = () => setWhen(lastSent());
    window.addEventListener(SENT, update);
    return () => window.removeEventListener(SENT, update);
  }, []);

  const send = async () => {
    if (!ready || busy) return;
    setBusy(true);
    setMsg(null);
    try {
      const tabs = await sendToSheets(settings, can, me?.name || user?.email || '');
      setMsg({ ok: true, text: `Sent to Google Sheets: ${tabs.join(', ')}.` });
      window.dispatchEvent(new Event(SENT));
    } catch (e) {
      setMsg({ ok: false, text: (e as Error).message });
    } finally {
      setBusy(false);
    }
  };

  if (!ready) return null;
  return (
    <div className="stack" style={{ gap: 'var(--s-xs)' }}>
      <div className="row wrap">
        <button className="btn outline sm" disabled={busy || disabled} onClick={() => void send()} title="Copy Farms, Payments, Users and the Audit log to your Google Sheet">
          {busy ? <span className="spinner sm" aria-hidden /> : <Icon name="export" />} <span className="btn-text">{busy ? 'Sending…' : 'Send to Google Sheets'}</span>
        </button>
        {when && <span className="small muted">Google Sheets updated {when.toLocaleString('en-GB', { dateStyle: 'medium', timeStyle: 'short' })}</span>}
      </div>
      {msg && <small className={msg.ok ? 'muted' : 'error-text'}>{msg.text}</small>}
    </div>
  );
}

/**
 * Mounted once in the control panel. With "keep up to date" on, it sends when the
 * panel opens (if the last send is over 10 minutes old) and a few seconds after
 * every change made in the panel (removing a farm, a payment, a plan…). Quiet:
 * a failed background send is retried on the next change or the next visit.
 */
export function SheetsAutoSync() {
  const { can, me } = useAdmin();
  const { user } = useSession();
  const settings = useRef<SheetsSettings | null>(null);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const busy = useRef(false);

  const send = useCallback(async () => {
    const s = settings.current;
    if (!s?.auto || !sheetsUrlOk(s.url) || !s.secret || busy.current) return;
    busy.current = true;
    try {
      await sendToSheets(s, can, me?.name || user?.email || '');
      window.dispatchEvent(new Event(SENT));
    } catch {
      // Tried again on the next change or visit.
    } finally {
      busy.current = false;
    }
  }, [can, me?.name, user?.email]);

  useEffect(() => {
    if (!me) return;
    let live = true;
    void loadIntegrations()
      .then((i) => {
        if (!live) return;
        settings.current = i.sheets;
        if (sheetsDue()) void send();
      })
      .catch(() => undefined);
    const onChange = () => {
      if (timer.current) clearTimeout(timer.current);
      // Re-read the settings too: the change may have been to the Google Sheets settings themselves.
      timer.current = setTimeout(() => {
        void loadIntegrations()
          .then((i) => {
            settings.current = i.sheets;
            return send();
          })
          .catch(() => undefined);
      }, 3000);
    };
    window.addEventListener('farmtap:admin-change', onChange);
    return () => {
      live = false;
      window.removeEventListener('farmtap:admin-change', onChange);
      if (timer.current) clearTimeout(timer.current);
    };
  }, [me, send]);

  return null;
}
