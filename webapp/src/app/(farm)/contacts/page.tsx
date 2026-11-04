'use client';

import Link from 'next/link';
import { useMemo, useState } from 'react';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { ConfirmDialog, Empty, Field, FormDialog, LoadError, PageHead, SearchBox, SkelRows, Stat, Tabs, useSave, useToast } from '@/components/ui';
import { dayKey, localIso, parseDate } from '@/lib/dates';
import { addRecord, mergeBody, putRecord, removeRecord, useRecords } from '@/lib/data';
import {
  alive,
  categoryForContact,
  categoryName,
  contactKindName,
  contactKinds,
  expenseCategories,
  isSupplier,
  manages,
  payMethodName,
  payMethods,
  recordDate,
  sourceOf,
  sourcePage,
  telLink,
  waLink,
  type ContactBody,
  type ExpenseBody,
  type FarmRecord,
  type PayMethod,
} from '@/lib/domain';
import { firebase } from '@/lib/firebase';
import { shortDate, ugx } from '@/lib/format';
import { expensesOf, removeWithExpenses, saveWithExpense } from '@/lib/linked';
import { useFarm, useSession } from '@/lib/session';
import { CallButtons, PaySupplier } from '@/components/farm';
import { useOpenFromUrl } from '@/lib/useOpen';

const phoneOk = (p: string) => /^\+?[\d\s-]{9,16}$/.test(p.trim());

function ContactForm({ c, onClose, kind }: { c?: FarmRecord<ContactBody>; onClose: () => void; kind?: string }) {
  const farm = useFarm();
  const { user, canSave, online } = useSession();
  const toast = useToast();
  const b = c?.body;
  const [f, setF] = useState({
    name: b?.name ?? '',
    kind: (b?.kind ?? kind ?? 'vet') as string,
    phone: b?.phone ?? '',
    phone2: b?.phone2 ?? '',
    org: b?.org ?? '',
    place: b?.place ?? '',
    note: b?.note ?? '',
    showWorkers: b?.showWorkers ?? true,
  });
  const { busy, error, setError, run } = useSave();
  const set = (k: keyof typeof f) => (e: { target: { value: string } }) => setF({ ...f, [k]: e.target.value });

  async function save() {
    if (!user) return;
    if (!f.name.trim()) return setError('Type the name.');
    if (!phoneOk(f.phone)) return setError('Type a phone number, e.g. 0772 123 456.');
    if (f.phone2.trim() && !phoneOk(f.phone2)) return setError('The second number does not look right.');
    const body = {
      name: f.name.trim(),
      kind: f.kind,
      phone: f.phone.trim(),
      phone2: f.phone2.trim() || null,
      org: f.org.trim() || null,
      place: f.place.trim() || null,
      note: f.note.trim() || null,
      showWorkers: f.showWorkers,
    };
    const { db } = firebase();
    const ok = await run(() => (c ? putRecord(db, farm.id, c, user.uid, mergeBody(c, body)) : addRecord(db, farm.id, 'contacts', user.uid, body)));
    if (ok) {
      toast(`${body.name} saved`);
      onClose();
    }
  }

  return (
    <FormDialog title={c ? `Edit ${b?.name}` : 'Add contact'} onClose={onClose} onSubmit={save} busy={busy} error={error} canSave={canSave} online={online} submit={c ? 'Save' : 'Add contact'} size="lg">
      <Fit kind="fields" cols={[1, 2, 2, 2]}>
        <Field label="Name">
          <input className="input" required value={f.name} onChange={set('name')} autoFocus maxLength={80} placeholder="e.g. Dr Okello" />
        </Field>
        <Field label="Who they are">
          <select className="input" value={f.kind} onChange={set('kind')}>
            {contactKinds.map((k) => (
              <option key={k} value={k}>
                {contactKindName[k]}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Phone">
          <input className="input" type="tel" required value={f.phone} onChange={set('phone')} placeholder="0772 123 456" />
        </Field>
        <Field label="Second phone (optional)">
          <input className="input" type="tel" value={f.phone2} onChange={set('phone2')} />
        </Field>
        <Field label={f.kind === 'vet' ? 'Clinic (optional)' : 'Shop or company (optional)'}>
          <input className="input" value={f.org} onChange={set('org')} placeholder={f.kind === 'vet' ? 'e.g. Mbarara Vet Clinic' : 'e.g. Kakoba Agro-vet'} />
        </Field>
        <Field label="Where (optional)">
          <input className="input" value={f.place} onChange={set('place')} placeholder="e.g. Mbarara town" />
        </Field>
      </Fit>
      <Field label="Note (optional)">
        <input className="input" value={f.note} onChange={set('note')} placeholder="e.g. Comes on Tuesdays; sells dairy meal at 60,000" maxLength={200} />
      </Field>
      <label className="check-row">
        <input type="checkbox" checked={f.showWorkers} onChange={(e) => setF({ ...f, showWorkers: e.target.checked })} />
        <span>Workers can see and call this contact</span>
      </label>
    </FormDialog>
  );
}

type Tab = 'all' | 'vets' | 'suppliers' | 'others';

export default function Contacts() {
  const farm = useFarm();
  const { user, canSave } = useSession();
  const toast = useToast();
  const boss = manages(farm);
  const contacts = useRecords<ContactBody>(farm.id, 'contacts');
  const expenses = useRecords<ExpenseBody>(boss ? farm.id : null, 'expenses');
  const [tab, setTab] = useState<Tab>('all');
  const [q, setQ] = useState('');
  const [adding, setAdding] = useOpenFromUrl();
  const [editing, setEditing] = useState<FarmRecord<ContactBody> | null>(null);
  const [paying, setPaying] = useState<FarmRecord<ContactBody> | null | 'any'>(null);
  const [open, setOpen] = useState<string | null>(null);
  const [removing, setRemoving] = useState<FarmRecord<ContactBody> | null>(null);
  const [undoPay, setUndoPay] = useState<FarmRecord<ExpenseBody> | null>(null);
  const [changing, setChanging] = useState<FarmRecord<ExpenseBody> | null>(null);
  const del = useSave();

  const list = alive(contacts.data)
    .filter((c) => boss || c.body.showWorkers !== false)
    .sort((a, b) => a.body.name.localeCompare(b.body.name));
  const spend = useMemo(() => {
    const m = new Map<string, { total: number; month: number; count: number; last: Date | null }>();
    const from = new Date(new Date().getFullYear(), new Date().getMonth(), 1);
    for (const e of alive(expenses.data)) {
      const id = e.body.supplierId;
      if (!id) continue;
      const at = recordDate(e, 'at');
      const s = m.get(id) ?? { total: 0, month: 0, count: 0, last: null };
      s.total += Number(e.body.amount) || 0;
      if (at >= from) s.month += Number(e.body.amount) || 0;
      s.count += 1;
      if (!s.last || at > s.last) s.last = at;
      m.set(id, s);
    }
    return m;
  }, [expenses.data]);

  const shown = list.filter((c) => {
    if (tab === 'vets' && c.body.kind !== 'vet') return false;
    if (tab === 'suppliers' && !['feedSupplier', 'drugSupplier', 'aiTechnician'].includes(c.body.kind)) return false;
    if (tab === 'others' && ['vet', 'feedSupplier', 'drugSupplier', 'aiTechnician'].includes(c.body.kind)) return false;
    const t = q.trim().toLowerCase();
    return !t || [c.body.name, c.body.org ?? '', c.body.phone, c.body.place ?? ''].some((v) => v.toLowerCase().includes(t));
  });
  const vets = list.filter((c) => c.body.kind === 'vet');
  const monthSpend = [...spend.values()].reduce((t, s) => t + s.month, 0);
  const payable = list.filter((c) => isSupplier(c.body.kind));

  return (
    <>
      <PageHead title="Contacts" subtitle="Vets, suppliers and everyone the farm calls. Workers see the ones you share.">
        {boss && (
          <button className="btn sm outline" onClick={() => setPaying('any')} disabled={!canSave || payable.length === 0}>
            <Icon name="money" /> Pay a supplier
          </button>
        )}
        {boss && (
          <button className="btn sm" onClick={() => setAdding(true)} disabled={!canSave}>
            <Icon name="plus" /> Add contact
          </button>
        )}
      </PageHead>
      <LoadError code={contacts.error} />

      {vets.length > 0 && (
        <section className="card emergency">
          <div className="row wrap">
            <div className="icon-chip bad">
              <Icon name="health" />
            </div>
            <div className="grow stack" style={{ gap: 0 }}>
              <strong>Sick animal? Call the vet</strong>
              <span className="small muted">
                {vets[0].body.name}
                {vets[0].body.org ? ` · ${vets[0].body.org}` : ''} · {vets[0].body.phone}
              </span>
            </div>
            <CallButtons phone={vets[0].body.phone} />
          </div>
        </section>
      )}

      {boss && (
        <Fit kind="stats" cols={[2, 2, 3, 3]}>
          <Stat loading={contacts.loading} icon="phone" label="Contacts" value={String(list.length)} hint={`${vets.length} vet${vets.length === 1 ? '' : 's'}`} />
          <Stat loading={expenses.loading} icon="receipt" label="Paid to suppliers this month" value={ugx(monthSpend)} hint="Feed, drugs, vets and others" tone="warn" />
          <Stat loading={contacts.loading} icon="truck" label="Suppliers" value={String(payable.length)} hint="People you buy from" tone="info" />
        </Fit>
      )}

      <div className="row wrap between">
        <Tabs
          label="Contacts"
          value={tab}
          onChange={setTab}
          items={[
            ['all', 'All', list.length],
            ['vets', 'Vets', vets.length],
            ['suppliers', 'Suppliers', list.filter((c) => ['feedSupplier', 'drugSupplier', 'aiTechnician'].includes(c.body.kind)).length],
            ['others', 'Others'],
          ]}
        />
        <SearchBox value={q} onChange={setQ} placeholder="Search name, shop or phone" />
      </div>

      {contacts.loading ? (
        <SkelRows rows={4} cols={4} />
      ) : shown.length === 0 ? (
        <Empty
          icon="phone"
          action={
            boss &&
            canSave && (
              <button className="btn sm" onClick={() => setAdding(true)}>
                <Icon name="plus" /> Add the vet first
              </button>
            )
          }
        >
          {list.length ? 'No contacts match.' : 'No contacts yet. Add your vet, feed supplier and agro-vet shop so everyone can call them.'}
        </Empty>
      ) : (
        <div className="contact-grid">
          {shown.map((c) => {
            const s = spend.get(c.id);
            const pays = boss && open === c.id ? alive(expenses.data).filter((e) => e.body.supplierId === c.id).sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime()) : [];
            return (
              <article key={c.id} className="card contact-card stack">
                <div className="row">
                  <span className={`avatar ${c.body.kind === 'vet' ? 'bad' : ''}`}>{c.body.name.slice(0, 1).toUpperCase()}</span>
                  <div className="grow stack" style={{ gap: 0 }}>
                    <strong>{c.body.name}</strong>
                    <span className="small muted">
                      {contactKindName[c.body.kind as keyof typeof contactKindName] ?? c.body.kind}
                      {c.body.org ? ` · ${c.body.org}` : ''}
                    </span>
                  </div>
                  {boss && c.body.showWorkers === false && <span className="chip">Owner only</span>}
                </div>
                <div className="small">
                  <span className="mono">{c.body.phone}</span>
                  {c.body.phone2 ? <span className="mono"> · {c.body.phone2}</span> : null}
                  {c.body.place ? <span className="muted"> · {c.body.place}</span> : null}
                </div>
                {c.body.note && <p className="small muted">{c.body.note}</p>}
                {boss && s && (
                  <button className="link-btn small" onClick={() => setOpen(open === c.id ? null : c.id)}>
                    Spent {ugx(s.total)} in {s.count} payment{s.count === 1 ? '' : 's'}
                    {s.month ? ` · ${ugx(s.month)} this month` : ''} {open === c.id ? '▲' : '▼'}
                  </button>
                )}
                {pays.length > 0 && (
                  <div className="list small">
                    {pays.slice(0, 12).map((e) => {
                      const src = sourceOf(e.body);
                      return (
                        <div key={e.id} className="list-row wrap">
                          <span>{shortDate(recordDate(e, 'at'))}</span>
                          <span className="grow">
                            {categoryName[e.body.category] ?? e.body.category}
                            {e.body.note ? ` · ${e.body.note}` : ''}
                            {e.body.payMethod ? ` · ${payMethodName[e.body.payMethod] ?? e.body.payMethod}` : ''}
                          </span>
                          <strong className="num">{ugx(e.body.amount)}</strong>
                          {src && src !== 'supplierPayment' ? (
                            <Link className="small" href={sourcePage[src].href}>
                              {sourcePage[src].label}
                            </Link>
                          ) : (
                            canSave && (
                              <span className="row">
                                <button className="icon-btn" aria-label="Change payment" onClick={() => setChanging(e)}>
                                  <Icon name="edit" />
                                </button>
                                <button className="icon-btn" aria-label="Remove payment" onClick={() => setUndoPay(e)}>
                                  <Icon name="close" />
                                </button>
                              </span>
                            )
                          )}
                        </div>
                      );
                    })}
                  </div>
                )}
                <div className="row wrap">
                  <CallButtons phone={c.body.phone} />
                  <span className="grow" />
                  {boss && isSupplier(c.body.kind) && (
                    <button className="btn sm outline" onClick={() => setPaying(c)} disabled={!canSave}>
                      <Icon name="money" /> Pay
                    </button>
                  )}
                  {boss && (
                    <button className="icon-btn" aria-label={`Edit ${c.body.name}`} onClick={() => setEditing(c)} disabled={!canSave}>
                      <Icon name="edit" />
                    </button>
                  )}
                  {boss && (
                    <button className="icon-btn" aria-label={`Remove ${c.body.name}`} onClick={() => setRemoving(c)} disabled={!canSave}>
                      <Icon name="close" />
                    </button>
                  )}
                </div>
              </article>
            );
          })}
        </div>
      )}

      {adding && <ContactForm onClose={() => setAdding(false)} />}
      {editing && <ContactForm c={editing} onClose={() => setEditing(null)} />}
      {paying && <PaySupplier contacts={payable} contact={paying === 'any' ? undefined : paying} onClose={() => setPaying(null)} />}
      {changing && <PaySupplier contacts={payable} edit={changing} onClose={() => setChanging(null)} />}
      {removing && (
        <ConfirmDialog
          title={`Remove ${removing.body.name}?`}
          confirm="Remove"
          danger
          busy={del.busy}
          error={del.error}
          onClose={() => setRemoving(null)}
          onConfirm={async () => {
            if (!user) return;
            if (await del.run(() => removeRecord(firebase().db, farm.id, removing, user.uid))) {
              toast('Contact removed');
              setRemoving(null);
            }
          }}
        >
          Payments made to them stay in Money.
        </ConfirmDialog>
      )}
      {undoPay && (
        <ConfirmDialog
          title="Remove this payment?"
          confirm="Remove"
          danger
          busy={del.busy}
          error={del.error}
          onClose={() => setUndoPay(null)}
          onConfirm={async () => {
            if (!user) return;
            if (await del.run(() => removeWithExpenses(firebase().db, farm.id, user.uid, null, [undoPay, ...expensesOf(undoPay.id, expenses.data)]))) {
              toast('Payment removed from Money too');
              setUndoPay(null);
            }
          }}
        >
          {ugx(undoPay.body.amount)} on {shortDate(recordDate(undoPay, 'at'))}. It is removed from Money and the supplier total too.
        </ConfirmDialog>
      )}
    </>
  );
}
