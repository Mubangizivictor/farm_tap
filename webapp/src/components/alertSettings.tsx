'use client';

// Farm reminders (decision 0024): which alerts go out, how, and at what time.
// Saved as the settings/alerts record, the same one the phone app and the
// server reminder job read (shared/alerts.ts).

import { useEffect, useState } from 'react';
import { useSave, useToast } from '@/components/ui';
import { upsertRecord, useRecords } from '@/lib/data';
import { manages, type Farm } from '@/lib/domain';
import { firebase } from '@/lib/firebase';
import { useSession } from '@/lib/session';
import { alertSettingsFrom, type AlertSettings } from '@/shared/alerts';

const WHAT: [keyof AlertSettings, string, string][] = [
  ['duties', 'Duty roster', 'The day before and on the morning of each duty, including stand-ins.'],
  ['vaccinations', 'Vaccinations', 'The day before a vaccination is due, on the day, and when it is late.'],
  ['calving', 'Calving and breeding', 'A week and a day before calving, heat checks and pregnancy checks.'],
  ['trial', 'Free trial and plan', 'Three days and one day before your trial or plan ends.'],
];

const HOW: [keyof AlertSettings, string, string][] = [
  ['push', 'Phone notifications', 'Free. Shows on phones with the FarmTap app.'],
  ['whatsapp', 'WhatsApp', 'Free when sent from the farm phone. Automatic sending needs a WhatsApp account set up by FarmTap.'],
  ['sms', 'SMS', 'Sent from the farm phone, or automatically when FarmTap switches on paid SMS.'],
];

export function AlertSettingsSection({ farm }: { farm: Farm }) {
  const { user, canSave } = useSession();
  const toast = useToast();
  const rec = useRecords<Record<string, unknown>>(farm.id, 'settings');
  const stored = rec.data.find((r) => r.id === 'alerts')?.body;
  const [s, setS] = useState<AlertSettings>(() => alertSettingsFrom(stored));
  const [dirty, setDirty] = useState(false);
  const save = useSave();
  const boss = manages(farm);
  useEffect(() => {
    if (!dirty) setS(alertSettingsFrom(stored));
  }, [stored, dirty]);

  const flip = (k: keyof AlertSettings) => {
    setS({ ...s, [k]: !s[k] });
    setDirty(true);
  };

  async function submit() {
    if (!user) return;
    const ok = await save.run(() => upsertRecord(firebase().db, farm.id, 'settings', 'alerts', user.uid, { ...s }));
    if (ok) {
      setDirty(false);
      toast('Reminders saved');
    }
  }

  const row = ([k, label, hint]: [keyof AlertSettings, string, string]) => (
    <label key={k} className="check-row">
      <input type="checkbox" checked={Boolean(s[k])} onChange={() => flip(k)} disabled={!boss} />
      <span className="stack tight">
        <strong>{label}</strong>
        <small className="muted">{hint}</small>
      </span>
    </label>
  );

  return (
    <section className="card stack lg">
      <div className="card-head">
        <h2>Reminders</h2>
      </div>
      <p className="small muted">FarmTap reminds the right people about duties, vaccinations, calving and your plan. The person on duty gets it; owners and managers get all of them.</p>
      <div className="stack">
        <strong className="small">What to remind about</strong>
        {WHAT.map(row)}
      </div>
      <div className="stack">
        <strong className="small">How to send</strong>
        {HOW.map(row)}
      </div>
      <label className="field short">
        <span>Send at</span>
        <select
          className="input"
          value={s.hour}
          disabled={!boss}
          onChange={(e) => {
            setS({ ...s, hour: Number(e.target.value) });
            setDirty(true);
          }}
        >
          {Array.from({ length: 17 }, (_, i) => i + 4).map((h) => (
            <option key={h} value={h}>
              {`${h % 12 || 12}:00 ${h < 12 ? 'am' : 'pm'}`}
            </option>
          ))}
        </select>
      </label>
      {save.error && <p className="banner bad small">{save.error}</p>}
      {boss ? (
        <div className="row">
          <button className="btn" type="button" disabled={!dirty || save.busy || !canSave} onClick={() => void submit()}>
            {save.busy ? 'Saving…' : 'Save reminders'}
          </button>
        </div>
      ) : (
        <p className="small muted">Only the owner or a manager can change reminders.</p>
      )}
    </section>
  );
}
