'use client';

import { collection, doc, getDocs } from 'firebase/firestore';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Suspense, useMemo, useState } from 'react';
import { Confirm, MsgBanner, Need, useAction, useLoad } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { Loading } from '@/components/Loading';
import { Empty, PageHead, SearchBox } from '@/components/ui';
import { adminChange, downloadCsv, loadAllFarms, updateOp } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { parseDate } from '@/lib/dates';
import { firebase } from '@/lib/firebase';
import { shortDate } from '@/lib/format';
import { sectorName } from '@/lib/labels';

interface Account {
  uid: string;
  name: string;
  email: string;
  phone: string;
  farms: { id: string; name: string; role: string }[];
  ownedFarms: number;
  farmLimit: number;
  disabled: boolean;
  disabledReason: string;
  worker: boolean;
}

async function loadAccounts(): Promise<Account[]> {
  const { db } = firebase();
  const [users, farms] = await Promise.all([getDocs(collection(db, 'users')), loadAllFarms()]);
  const farmName = new Map(farms.map((f) => [f.id, f.name]));
  const owners = new Map(farms.map((f) => [f.owner.uid, f.owner]));
  return users.docs.map((d) => {
    const u = d.data();
    const owner = owners.get(d.id);
    const login = (u.staffLogin ?? {}) as { tenantId?: string };
    const memberships = ((u.memberships as { tenantId: string; role?: string }[] | undefined) ?? []).map((m) => ({ id: m.tenantId, name: farmName.get(m.tenantId) ?? m.tenantId, role: m.role ?? (login.tenantId ? 'worker' : '') }));
    return {
      uid: d.id,
      name: (u.name as string) || owner?.name || '',
      email: owner?.email || (u.email as string) || '',
      phone: (u.phone as string) || '',
      farms: memberships,
      ownedFarms: Number(u.ownedFarms ?? 0),
      farmLimit: Number(u.farmLimit ?? 1),
      disabled: u.disabled === true,
      disabledReason: (u.disabledReason as string) ?? '',
      worker: !!login.tenantId,
    };
  });
}

function Accounts() {
  const { actor, can } = useAdmin();
  const params = useSearchParams();
  const accounts = useLoad(loadAccounts);
  const [q, setQ] = useState(params.get('q') ?? '');
  const [ask, setAsk] = useState<Account | null>(null);
  const [reason, setReason] = useState('');
  const act = useAction();

  const list = useMemo(() => {
    const t = q.trim().toLowerCase();
    return (accounts.data ?? []).filter((a) => !t || [a.name, a.email, a.phone, a.uid, ...a.farms.map((f) => f.name)].some((v) => v.toLowerCase().includes(t)));
  }, [accounts.data, q]);

  const setDisabled = (a: Account, on: boolean) =>
    act
      .run(
        () =>
          adminChange(actor, { action: on ? 'user.disable' : 'user.enable', target: `users/${a.uid}`, details: { reason, name: a.name } }, [
            updateOp(doc(firebase().db, 'users', a.uid), { disabled: on, disabledReason: on ? reason.trim() : '' }),
          ]),
        on ? 'Account disabled. The apps sign it out and show who to call.' : 'Account enabled again.',
      )
      .then(() => {
        setAsk(null);
        accounts.reload();
      });

  return (
    <>
      <div className="row wrap">
        <SearchBox value={q} onChange={setQ} placeholder="Name, email, phone, farm" />
        <span className="small muted">{list.length} accounts</span>
      </div>
      <MsgBanner msg={act.msg} />
      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr>
              <th>Person</th>
              <th>Farms</th>
              <th>Kind</th>
              <th>Status</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {list.map((a) => (
              <tr key={a.uid}>
                <td>
                  <div className="stack" style={{ gap: 0 }}>
                    <strong>{a.name || 'No name'}</strong>
                    <span className="small muted">{a.email || a.phone || a.uid}</span>
                  </div>
                </td>
                <td style={{ whiteSpace: 'normal' }}>
                  {a.farms.map((f) => (
                    <Link key={f.id} href={`/admin/farm/?id=${f.id}`} className="chip brand" style={{ marginRight: 'var(--s-xs)', textDecoration: 'none' }}>
                      {f.name}
                    </Link>
                  ))}
                  {!a.farms.length && <span className="muted small">None</span>}
                </td>
                <td>{a.worker ? 'Worker (phone + PIN)' : a.ownedFarms ? `Owner${a.farmLimit > 1 ? `, up to ${a.farmLimit} farms` : ''}` : 'Manager'}</td>
                <td>{a.disabled ? <span className="chip bad" title={a.disabledReason}>Disabled</span> : <span className="chip ok">Active</span>}</td>
                <td className="r">
                  {can('users') &&
                    (a.disabled ? (
                      <button className="btn sm outline" disabled={act.busy} onClick={() => void setDisabled(a, false)}>
                        Enable
                      </button>
                    ) : (
                      <button className="btn sm ghost" onClick={() => setAsk(a)}>
                        Disable
                      </button>
                    ))}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {accounts.data && !list.length && <Empty>Nobody matches.</Empty>}
        {!accounts.data && !accounts.error && <Empty>Loading accounts…</Empty>}
        {accounts.error && <Empty>Could not load accounts ({accounts.error}).</Empty>}
      </div>
      <p className="small muted">To reset a worker&apos;s card PIN or revoke a card, open their farm and go to People.</p>
      {ask && (
        <Confirm title={`Disable ${ask.name || ask.email || 'this account'}?`} confirm="Disable" danger busy={act.busy} onClose={() => setAsk(null)} onConfirm={() => void setDisabled(ask, true)}>
          <p className="muted">The web app and the phones sign this account out and show the support number. Their farm&apos;s records are not touched. You can enable it again any time.</p>
          <label className="field">
            <span>Reason (kept in the audit log)</span>
            <input className="input" value={reason} onChange={(e) => setReason(e.target.value)} />
          </label>
        </Confirm>
      )}
    </>
  );
}

function Waitlist() {
  const list = useLoad(async () => {
    const s = await getDocs(collection(firebase().db, 'waitlist'));
    return s.docs.map((d) => ({ id: d.id, ...(d.data() as { sector?: string; name?: string; whatsapp?: string; createdAt?: unknown }) })).sort((a, b) => (parseDate(b.createdAt)?.getTime() ?? 0) - (parseDate(a.createdAt)?.getTime() ?? 0));
  });
  return (
    <>
      <div className="row">
        <span className="small muted grow">People who asked for a sector that is not open yet. Tell them first when it opens.</span>
        <button
          className="btn sm outline"
          onClick={() =>
            downloadCsv('farmtap-waitlist', ['Name', 'WhatsApp', 'Sector', 'Joined'], (list.data ?? []).map((w) => [w.name ?? '', w.whatsapp ?? '', sectorName[w.sector ?? ''] ?? w.sector ?? '', shortDate(parseDate(w.createdAt))]))
          }
        >
          <Icon name="download" /> CSV
        </button>
      </div>
      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>WhatsApp</th>
              <th>Sector</th>
              <th>Joined</th>
            </tr>
          </thead>
          <tbody>
            {(list.data ?? []).map((w) => (
              <tr key={w.id}>
                <td>{w.name}</td>
                <td>
                  {w.whatsapp && (
                    <a href={`https://wa.me/${w.whatsapp.replace(/\D/g, '').replace(/^0/, '256')}`} target="_blank" rel="noreferrer">
                      {w.whatsapp}
                    </a>
                  )}
                </td>
                <td>{sectorName[w.sector ?? ''] ?? w.sector}</td>
                <td>{shortDate(parseDate(w.createdAt))}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {list.data && !list.data.length && <Empty>Nobody yet.</Empty>}
        {list.error && <Empty>Your role cannot see the waiting list.</Empty>}
      </div>
    </>
  );
}

function UsersView() {
  const params = useSearchParams();
  const [tab, setTab] = useState(params.get('tab') === 'waitlist' ? 'waitlist' : 'accounts');
  return (
    <>
      <PageHead title="Users" subtitle="Everyone with a FarmTap account, and the waiting list" />
      <div className="tabs" role="tablist">
        <button role="tab" aria-selected={tab === 'accounts'} onClick={() => setTab('accounts')}>
          Accounts
        </button>
        <button role="tab" aria-selected={tab === 'waitlist'} onClick={() => setTab('waitlist')}>
          Waiting list
        </button>
      </div>
      {tab === 'accounts' ? <Accounts /> : <Waitlist />}
    </>
  );
}

export default function Users() {
  return (
    <Need perm={['users', 'support']}>
      <Suspense fallback={<Loading />}>
        <UsersView />
      </Suspense>
    </Need>
  );
}
