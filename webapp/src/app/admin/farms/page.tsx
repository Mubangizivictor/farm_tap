'use client';

import { useRouter } from 'next/navigation';
import { useMemo, useState } from 'react';
import { Need, useLoad } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { Empty, LoadError, PageHead, SearchBox } from '@/components/ui';
import { downloadCsv, loadAllFarms, loadPlans } from '@/lib/admin';
import { farmPlan, farmStatus, planOf } from '@/lib/adminView';
import { date, shortDate } from '@/lib/format';
import { sectorName } from '@/lib/labels';

const filters = [
  ['all', 'All'],
  ['pending', 'To review'],
  ['trial', 'On trial'],
  ['paid', 'Paid'],
  ['grace', 'Overdue'],
  ['readOnly', 'Lapsed'],
  ['suspended', 'Suspended'],
] as const;

export default function AdminFarms() {
  const router = useRouter();
  const farms = useLoad(loadAllFarms);
  const plans = useLoad(loadPlans);
  const [q, setQ] = useState('');
  const [filter, setFilter] = useState<(typeof filters)[number][0]>('all');
  const [sector, setSector] = useState('all');
  const now = new Date();

  const list = useMemo(() => {
    const t = q.trim().toLowerCase();
    return (farms.data ?? []).filter((f) => {
      if (sector !== 'all' && f.sector !== sector) return false;
      const kind = farmPlan(f, now).kind;
      if (filter === 'pending' && f.review !== 'pending') return false;
      if (filter === 'suspended' && f.status !== 'suspended') return false;
      if (!['all', 'pending', 'suspended'].includes(filter) && (kind !== filter || f.status === 'suspended')) return false;
      if (!t) return true;
      return [f.name, f.owner.name, f.owner.email, f.district, f.village, f.whatsapp, f.sms, f.id].some((v) => v.toLowerCase().includes(t));
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [farms.data, q, filter, sector]);

  const sectors = [...new Set((farms.data ?? []).map((f) => f.sector))];

  function csv() {
    downloadCsv(
      `farmtap-farms-${new Date().toISOString().slice(0, 10)}`,
      ['Farm', 'Sector', 'Type', 'District', 'Owner', 'Email', 'WhatsApp', 'Status', 'Plan', 'Trial ends', 'Paid until', 'Created', 'Last seen', 'ID'],
      list.map((f) => [
        f.name,
        sectorName[f.sector] ?? f.sector,
        f.type,
        f.district,
        f.owner.name,
        f.owner.email,
        f.whatsapp,
        farmStatus(f, now).text,
        planOf(f, plans.data ?? []).name,
        date(f.trialEndsAt),
        date(f.paidUntil),
        date(f.createdAt),
        date(f.lastSeenAt),
        f.id,
      ]),
    );
  }

  return (
    <Need perm={['farms', 'support', 'finance', 'users']}>
      <PageHead title="Farms" subtitle={`${list.length} of ${farms.data?.length ?? 0} farms and centres`}>
        <SearchBox value={q} onChange={setQ} placeholder="Name, owner, phone, district" />
        <button className="btn outline sm" onClick={csv}>
          <Icon name="download" /> CSV
        </button>
        <button className="btn outline sm" onClick={farms.reload}>
          <Icon name="refresh" /> Refresh
        </button>
      </PageHead>

      <div className="row wrap">
        <div className="seg" role="group" aria-label="Status">
          {filters.map(([k, label]) => (
            <button key={k} aria-pressed={filter === k} onClick={() => setFilter(k)}>
              {label}
            </button>
          ))}
        </div>
        {sectors.length > 1 && (
          <select className="input" style={{ width: 'auto' }} value={sector} onChange={(e) => setSector(e.target.value)} aria-label="Sector">
            <option value="all">All sectors</option>
            {sectors.map((s) => (
              <option key={s} value={s}>
                {sectorName[s] ?? s}
              </option>
            ))}
          </select>
        )}
      </div>

      <LoadError code={farms.error} />

      <div className="table-wrap">
        <table className="table">
          <thead>
            <tr>
              <th>Farm</th>
              <th>Owner</th>
              <th>Sector</th>
              <th>Status</th>
              <th>Plan</th>
              <th>Created</th>
              <th>Last seen</th>
            </tr>
          </thead>
          <tbody>
            {list.map((f) => {
              const st = farmStatus(f, now);
              return (
                <tr key={f.id} className="clickable" onClick={() => router.push(`/admin/farm/?id=${f.id}`)}>
                  <td>
                    <div className="stack" style={{ gap: 0 }}>
                      <strong>{f.name}</strong>
                      <span className="small muted">
                        {f.type === 'centre' ? 'Collection centre' : f.type === 'both' ? 'Farm and centre' : 'Farm'}
                        {f.district ? ` · ${f.district}` : ''}
                      </span>
                    </div>
                  </td>
                  <td>
                    <div className="stack" style={{ gap: 0 }}>
                      <span>{f.owner.name || '—'}</span>
                      <span className="small muted">{f.owner.email || f.whatsapp}</span>
                    </div>
                  </td>
                  <td>{sectorName[f.sector] ?? f.sector}</td>
                  <td>
                    <div className="row wrap" style={{ gap: 'var(--s-xs)' }}>
                      <span className={`chip ${st.tone}`}>{st.text}</span>
                      {f.review === 'pending' && <span className="chip warn">Review</span>}
                    </div>
                  </td>
                  <td>{planOf(f, plans.data ?? []).name}</td>
                  <td>{shortDate(f.createdAt)}</td>
                  <td>{f.lastSeenAt ? shortDate(f.lastSeenAt) : <span className="muted">—</span>}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
        {farms.data && !list.length && <Empty>No farms match.</Empty>}
        {!farms.data && !farms.error && <Empty>Loading farms…</Empty>}
      </div>
    </Need>
  );
}
