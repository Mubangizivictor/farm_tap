'use client';

import { useEffect, useState } from 'react';
import { collection, doc, getDoc, getDocs, onSnapshot, query, where } from 'firebase/firestore';
import { onAuthStateChanged, type User } from 'firebase/auth';
import { Icon } from '@/components/Icon';
import { Loading } from '@/components/Loading';
import { firebase } from '@/lib/firebase';
import { localIso, startOfMonth } from '@/lib/dates';
import { litres, shortDate, time, words } from '@/lib/format';
import { type DeliveryBody, type FarmRecord, type FarmerBody, recordDate } from '@/lib/domain';
import { supportWhatsAppLink } from '@/lib/support';

interface FarmerLink { tenantId: string; farmerId: string; }
interface FarmInfo { name: string; }

interface SupplierData {
  farmer: FarmRecord<FarmerBody>;
  farm: FarmInfo;
  deliveries: FarmRecord<DeliveryBody>[];
}

function SessionStats({ deliveries }: { deliveries: FarmRecord<DeliveryBody>[] }) {
  const now = new Date();
  const monthFrom = startOfMonth(now);
  const accepted = deliveries.filter((d) => d.body.test !== 'failed');
  const thisMonth = accepted.filter((d) => recordDate(d, 'at') >= monthFrom);
  const totalL = thisMonth.reduce((t, d) => t + (Number(d.body.litres) || 0), 0);
  const rejected = deliveries.filter((d) => d.body.test === 'failed' && recordDate(d, 'at') >= monthFrom).length;
  const lastDelivery = accepted.length > 0 ? accepted.sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime())[0] : null;

  return (
    <div className="grid">
      <div className="card flat stat">
        <span className="label">This month</span>
        <span className="value">{litres(totalL)}</span>
        <span className="hint">{thisMonth.length} deliveries</span>
      </div>
      <div className="card flat stat">
        <span className="label">Rejected</span>
        <span className="value" style={{ color: rejected > 0 ? 'var(--c-bad)' : undefined }}>{rejected}</span>
        <span className="hint">this month</span>
      </div>
      <div className="card flat stat">
        <span className="label">Last delivery</span>
        <span className="value" style={{ fontSize: 'var(--t-base)' }}>{lastDelivery ? shortDate(recordDate(lastDelivery, 'at')) : '–'}</span>
        <span className="hint">{lastDelivery ? litres(lastDelivery.body.litres) : 'No recent delivery'}</span>
      </div>
    </div>
  );
}

function DeliveryList({ deliveries }: { deliveries: FarmRecord<DeliveryBody>[] }) {
  const sorted = [...deliveries].sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime());
  if (sorted.length === 0) {
    return <p className="muted" style={{ padding: 'var(--s-md)' }}>No deliveries recorded yet.</p>;
  }
  return (
    <div className="list">
      {sorted.slice(0, 60).map((d) => {
        const at = recordDate(d, 'at');
        const failed = d.body.test === 'failed';
        return (
          <div key={d.id} className="list-row">
            <div className="stack grow" style={{ gap: 'var(--s-xxs)' }}>
              <span>{shortDate(at)} · {time(at)} · {words(d.body.session)}</span>
              {d.body.note && <span className="small muted">{d.body.note}</span>}
            </div>
            <span className={`chip ${failed ? 'bad' : 'ok'}`}>
              {failed ? (words(d.body.rejectReason) || 'Rejected') : litres(d.body.litres)}
            </span>
          </div>
        );
      })}
    </div>
  );
}

function SupplierPortal({ user, links }: { user: User; links: FarmerLink[] }) {
  const [data, setData] = useState<SupplierData[]>([]);
  const [loading, setLoading] = useState(true);
  const [active, setActive] = useState(0);

  useEffect(() => {
    if (!links.length) { setLoading(false); return; }
    const { db } = firebase();
    const now = new Date();
    const monthFrom = startOfMonth(now);

    Promise.all(
      links.map(async ({ tenantId, farmerId }) => {
        const [farmSnap, farmerSnap] = await Promise.all([
          getDoc(doc(db, 'tenants', tenantId)),
          getDoc(doc(db, 'tenants', tenantId, 'farmers', farmerId)),
        ]);
        if (!farmSnap.exists() || !farmerSnap.exists()) return null;
        const farmer: FarmRecord<FarmerBody> = { id: farmerId, ...farmerSnap.data() } as FarmRecord<FarmerBody>;
        const farm: FarmInfo = { name: (farmSnap.data().name as string) ?? '' };

        const q = query(
          collection(db, 'tenants', tenantId, 'deliveries'),
          where('body.farmerId', '==', farmerId),
          where('createdAt', '>=', localIso(monthFrom)),
        );
        const snap = await getDocs(q);
        const deliveries = snap.docs.map((d) => d.data() as FarmRecord<DeliveryBody>).filter((d) => !d.isDeleted);
        return { farmer, farm, deliveries };
      }),
    ).then((results) => {
      setData(results.filter((r): r is SupplierData => r !== null));
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [links]);

  if (loading) return <Loading />;

  if (!data.length) {
    return (
      <div className="full-screen stack" style={{ alignItems: 'center', justifyContent: 'center', gap: 'var(--s-lg)', textAlign: 'center', padding: 'var(--s-xl)' }}>
        <Icon name="truck" className="icon" />
        <div className="stack" style={{ gap: 'var(--s-xs)' }}>
          <h2>No linked farms</h2>
          <p className="muted">Ask your collection centre to send you an invite link so your deliveries appear here.</p>
          <a className="btn outline" href={supportWhatsAppLink('Hello FarmTap, I need an invite link for the supplier portal.')} target="_blank" rel="noreferrer">
            <Icon name="whatsapp" /> Contact support
          </a>
        </div>
      </div>
    );
  }

  const current = data[active];

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="row" style={{ padding: 'var(--s-xs) var(--s-sm)' }}>
          <div className="logo-mark" aria-hidden />
          <strong className="brand-text">FarmTap</strong>
        </div>
        <nav className="nav" aria-label="Main">
          {data.map((d, i) => (
            <button key={d.farmer.id} onClick={() => setActive(i)} aria-current={i === active ? 'page' : undefined} style={{ width: '100%', textAlign: 'left' }}>
              <Icon name="truck" />
              <span>{d.farm.name}</span>
            </button>
          ))}
        </nav>
        <div className="grow" />
        <div className="side-foot card flat small">
          <strong>{current.farmer.body.name}</strong>
          <div className="muted">Supplier portal</div>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div className="logo-mark show-sm-only" aria-hidden />
          <div className="stack grow" style={{ gap: 0 }}>
            <span className="farm-name">{current.farmer.body.name}</span>
            <span className="small muted hide-sm">{current.farm.name}</span>
          </div>
          <a className="btn outline sm" href="/sign-in/" style={{ textDecoration: 'none' }}>Sign out</a>
        </header>

        <div className="content">
          <div className="page-head">
            <div>
              <h1>My deliveries</h1>
              <p className="muted">{current.farm.name}</p>
            </div>
          </div>

          <SessionStats deliveries={current.deliveries} />

          <section className="card" style={{ marginTop: 'var(--s-lg)' }}>
            <h3 style={{ padding: 'var(--s-md) var(--s-md) 0' }}>Delivery history (last 30 days)</h3>
            <DeliveryList deliveries={current.deliveries} />
          </section>

          {current.farmer.body.card && (
            <section className="card flat" style={{ marginTop: 'var(--s-md)', padding: 'var(--s-md)' }}>
              <div className="row" style={{ gap: 'var(--s-sm)' }}>
                <Icon name="tag" />
                <span>Your card number: <strong>{current.farmer.body.card}</strong></span>
              </div>
            </section>
          )}

          <div style={{ padding: 'var(--s-xl) 0', textAlign: 'center' }}>
            <p className="small muted">Need help? <a href={supportWhatsAppLink(`Hello, I am ${current.farmer.body.name} from ${current.farm.name}.`)} target="_blank" rel="noreferrer">WhatsApp support</a></p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function SupplierPage() {
  const [user, setUser] = useState<User | null | undefined>(undefined);
  const [links, setLinks] = useState<FarmerLink[] | null>(null);

  useEffect(() => {
    const { auth, db } = firebase();
    return onAuthStateChanged(auth, async (u) => {
      setUser(u);
      if (!u) { setLinks([]); return; }
      try {
        const snap = await getDoc(doc(db, 'users', u.uid));
        setLinks((snap.data()?.farmerLinks as FarmerLink[] | undefined) ?? []);
      } catch {
        setLinks([]);
      }
    });
  }, []);

  if (user === undefined || links === null) return <Loading />;

  if (!user) {
    return (
      <div className="full-screen stack" style={{ alignItems: 'center', justifyContent: 'center', gap: 'var(--s-lg)', textAlign: 'center', padding: 'var(--s-xl)' }}>
        <div className="logo-mark" aria-hidden style={{ width: 'var(--s-xxl)', height: 'var(--s-xxl)' }} />
        <div className="stack" style={{ gap: 'var(--s-xs)' }}>
          <h2>Supplier Portal</h2>
          <p className="muted">See your milk delivery records and payments online.</p>
        </div>
        <a className="btn" href="/sign-in/?next=/supplier/">Sign in with Google</a>
      </div>
    );
  }

  return <SupplierPortal user={user} links={links} />;
}
