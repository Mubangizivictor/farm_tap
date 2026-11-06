'use client';

// Supplier portal: a farmer who brings milk to a collection centre sees
// their own deliveries, live, after accepting the centre's invite link.
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useEffect, useMemo, useState } from 'react';
import { collection, doc, getDoc, onSnapshot, query, where } from 'firebase/firestore';
import { Fit } from '@/components/fit';
import { Icon } from '@/components/Icon';
import { Loading } from '@/components/Loading';
import { CardHead, Empty, LoadError, PageHead, Seg, SkelRows, Stat } from '@/components/ui';
import { addDays, startOfDay, startOfMonth } from '@/lib/dates';
import { type DeliveryBody, type FarmRecord, type FarmerBody, recordDate } from '@/lib/domain';
import { firebase } from '@/lib/firebase';
import { count, date, litres, shortDate, time, words } from '@/lib/format';
import { useSession } from '@/lib/session';
import { supportWhatsAppLink } from '@/lib/support';

interface FarmerLink {
  tenantId: string;
  farmerId: string;
}

interface Linked {
  link: FarmerLink;
  farmName: string;
  farmer: FarmerBody | null;
}

/** This farmer's deliveries at one centre, live. Only theirs: the rules check the link. */
function useDeliveries(link: FarmerLink | null) {
  const [state, setState] = useState<{ data: FarmRecord<DeliveryBody>[]; loading: boolean; error: string | null }>({ data: [], loading: true, error: null });
  useEffect(() => {
    if (!link) return;
    setState({ data: [], loading: true, error: null });
    const q = query(collection(firebase().db, 'tenants', link.tenantId, 'deliveries'), where('body.farmerId', '==', link.farmerId));
    return onSnapshot(
      q,
      (snap) => setState({ data: snap.docs.map((d) => d.data() as FarmRecord<DeliveryBody>).filter((d) => !d.isDeleted), loading: false, error: null }),
      (e) => setState({ data: [], loading: false, error: e.code }),
    );
  }, [link]);
  return state;
}

function Portal({ links, names }: { links: FarmerLink[]; names: Record<string, string> }) {
  const { signOut } = useSession();
  const router = useRouter();
  const [linked, setLinked] = useState<Linked[] | null>(null);
  const [active, setActive] = useState('0');

  useEffect(() => {
    const { db } = firebase();
    Promise.all(
      links.map(async (link) => {
        const [farm, farmer] = await Promise.all([
          getDoc(doc(db, 'tenants', link.tenantId)).catch(() => null),
          getDoc(doc(db, 'tenants', link.tenantId, 'farmers', link.farmerId)).catch(() => null),
        ]);
        // The farm itself is private to its members: the invite carried its name.
        const farmName = (farm?.exists() ? (farm.data().name as string) : '') || names[link.tenantId] || '';
        const body = farmer?.exists() ? ((farmer.data() as FarmRecord<FarmerBody>).body ?? null) : null;
        return { link, farmName, farmer: body };
      }),
    ).then(setLinked);
  }, [links, names]);

  const current = linked?.[Number(active)] ?? null;
  const deliveries = useDeliveries(current?.link ?? null);
  const now = new Date();

  const view = useMemo(() => {
    const monthFrom = startOfMonth(now);
    const since = addDays(startOfDay(now), -29);
    const sorted = [...deliveries.data].sort((a, b) => recordDate(b, 'at').getTime() - recordDate(a, 'at').getTime());
    const month = sorted.filter((d) => recordDate(d, 'at') >= monthFrom);
    const accepted = month.filter((d) => d.body.test !== 'failed');
    const rejected = month.filter((d) => d.body.test === 'failed');
    const days = new Set(accepted.map((d) => startOfDay(recordDate(d, 'at')).getTime()));
    return {
      recent: sorted.filter((d) => recordDate(d, 'at') >= since),
      monthLitres: accepted.reduce((t, d) => t + (Number(d.body.litres) || 0), 0),
      monthCount: accepted.length,
      rejected,
      days: days.size,
      last: sorted.find((d) => d.body.test !== 'failed') ?? null,
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [deliveries.data]);

  async function leave() {
    await signOut();
    router.replace('/sign-in/');
  }

  if (!linked) return <Loading />;

  const name = current?.farmer?.name || 'Supplier';
  const centre = current?.farmName || 'Your collection centre';

  return (
    <div className="shell supplier">
      <div className="main">
        <header className="topbar">
          <Link href="/supplier/" className="side-logo" aria-label="FarmTap" style={{ flex: 'none' }}>
            <span className="logo-mark" aria-hidden />
            <strong className="brand-text hide-sm">FarmTap</strong>
          </Link>
          <div className="stack grow" style={{ gap: 0 }}>
            <span className="farm-name">{name}</span>
            <span className="small muted">{centre}</span>
          </div>
          <button className="btn outline sm" onClick={() => void leave()}>
            <Icon name="logout" /> <span className="btn-text">Sign out</span>
          </button>
        </header>
        <div className="content">
          <PageHead title="My milk" subtitle={current?.farmer?.card ? `${centre} · card ${current.farmer.card}` : centre}>
            {linked.length > 1 && (
              <Seg label="Collection centre" value={active} onChange={setActive} items={linked.map((l, i) => [String(i), l.farmName || `Centre ${i + 1}`] as const)} />
            )}
          </PageHead>

          <LoadError code={deliveries.error} />

          <Fit kind="stats" cols={[2, 2, 4, 4]}>
            <Stat loading={deliveries.loading} icon="drop" label="This month" value={litres(view.monthLitres)} hint={`${count(view.monthCount)} deliveries accepted`} />
            <Stat loading={deliveries.loading} icon="calendar" label="Days delivered" value={count(view.days)} hint="this month" tone="info" />
            <Stat
              loading={deliveries.loading}
              icon="alert"
              label="Rejected"
              value={count(view.rejected.length)}
              hint={view.rejected.length ? `${litres(view.rejected.reduce((t, d) => t + (Number(d.body.litres) || 0), 0))} this month` : 'None this month'}
              tone={view.rejected.length ? 'bad' : undefined}
            />
            <Stat
              loading={deliveries.loading}
              icon="truck"
              label="Last delivery"
              value={view.last ? litres(view.last.body.litres) : '–'}
              hint={view.last ? `${date(recordDate(view.last, 'at'))} · ${words(view.last.body.session)}` : 'Nothing yet'}
              tone="gold"
            />
          </Fit>

          <section className="card">
            <CardHead title="Last 30 days" />
            {deliveries.loading ? (
              <SkelRows rows={5} cols={4} />
            ) : view.recent.length === 0 ? (
              <Empty icon="truck">No deliveries in the last 30 days. They show here as soon as the centre records them.</Empty>
            ) : (
              <div className="table-wrap">
                <table className="table rt">
                  <thead>
                    <tr>
                      <th>Day</th>
                      <th>Session</th>
                      <th className="num">Litres</th>
                      <th>Result</th>
                    </tr>
                  </thead>
                  <tbody>
                    {view.recent.map((d) => {
                      const at = recordDate(d, 'at');
                      const failed = d.body.test === 'failed';
                      return (
                        <tr key={d.id}>
                          <td data-label="Day" className="lead">
                            <strong>{shortDate(at)}</strong> <span className="small muted">· {time(at)}</span>
                          </td>
                          <td data-label="Session">{words(d.body.session)}</td>
                          <td data-label="Litres" className="num">{litres(d.body.litres)}</td>
                          <td data-label="Result">
                            {failed ? (
                              <span className="chip bad">Rejected{d.body.rejectReason ? `: ${words(d.body.rejectReason)}` : ''}</span>
                            ) : d.body.test === 'passed' ? (
                              <span className="chip ok">Accepted</span>
                            ) : (
                              <span className="chip">Not tested</span>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </section>

          <p className="small muted" style={{ textAlign: 'center' }}>
            Something wrong? Talk to {centre}, or{' '}
            <a href={supportWhatsAppLink(`Hello FarmTap, I am ${name}, a supplier at ${centre}.`)} target="_blank" rel="noreferrer">
              WhatsApp FarmTap
            </a>
            .
          </p>
        </div>
      </div>
    </div>
  );
}

function Message({ icon, title, children, action }: { icon?: 'truck' | 'alert'; title: string; children: React.ReactNode; action?: React.ReactNode }) {
  return (
    <div className="full-screen">
      <div className="box">
        {icon ? <Icon name={icon} /> : <div className="logo-mark lg" aria-hidden />}
        <h1>{title}</h1>
        <p className="muted">{children}</p>
        {action}
      </div>
    </div>
  );
}

export default function SupplierPage() {
  const { user } = useSession();
  const [links, setLinks] = useState<FarmerLink[] | null>(null);
  const [names, setNames] = useState<Record<string, string>>({});

  useEffect(() => {
    if (!user) return;
    getDoc(doc(firebase().db, 'users', user.uid))
      .then((snap) => {
        setNames((snap.data()?.centreNames as Record<string, string> | undefined) ?? {});
        setLinks((snap.data()?.farmerLinks as FarmerLink[] | undefined) ?? []);
      })
      .catch(() => setLinks([]));
  }, [user]);

  if (user === undefined || (user && links === null)) return <Loading />;

  if (!user) {
    return (
      <Message
        title="Your milk, on your phone"
        action={
          <Link className="btn" href={`/sign-in/?next=${encodeURIComponent('/supplier/')}`}>
            Sign in
          </Link>
        }
      >
        See every delivery you bring to your collection centre, as soon as it is recorded.
      </Message>
    );
  }

  if (!links?.length) {
    return (
      <Message
        icon="truck"
        title="Not linked to a centre yet"
        action={
          <a className="btn outline" href={supportWhatsAppLink('Hello FarmTap, I need an invite link for the supplier portal.')} target="_blank" rel="noreferrer">
            <Icon name="whatsapp" /> Ask for help
          </a>
        }
      >
        Ask your collection centre to send you an invite link. Open it on this phone and your deliveries show here.
      </Message>
    );
  }

  return <Portal links={links} names={names} />;
}
