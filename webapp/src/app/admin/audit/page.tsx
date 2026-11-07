'use client';

import { useState } from 'react';
import { Need, useLoad } from '@/components/admin';
import { Empty, PageHead, PrintButton } from '@/components/ui';
import { loadAudit, type AuditEntry } from '@/lib/admin';
import { date } from '@/lib/format';
import { downloadCsv } from '@/lib/csv';
import { Icon } from '@/components/Icon';

const ACTION_LABELS: Record<string, string> = {
  'secret.set': 'Set secret',
  'integrations.edit': 'Edit integrations',
  'config.settings': 'Edit settings',
  'announcement.create': 'Create announcement',
  'announcement.stop': 'Stop announcement',
  'staff.invite': 'Invite staff',
  'staff.edit': 'Edit staff',
  'staff.on': 'Enable staff',
  'staff.off': 'Disable staff',
  'staff.cancelInvite': 'Cancel invite',
  'farm.approve': 'Approve farm',
  'farm.reject': 'Reject farm',
  'farm.suspend': 'Suspend farm',
  'farm.reactivate': 'Reactivate farm',
  'farm.extend': 'Extend trial',
  'farm.plan': 'Change plan',
  'farm.features': 'Edit features',
  'farm.sms': 'Edit SMS settings',
  'farm.limit': 'Set farm limit',
  'payment.record': 'Record payment',
  'payment.void': 'Void payment',
  'users.disable': 'Disable user',
  'users.enable': 'Enable user',
  'users.pinReset': 'Reset PIN',
  'users.revokeCard': 'Revoke card',
  'plan.edit': 'Edit plan',
  'plan.add': 'Add plan',
  'smsPackage.edit': 'Edit SMS package',
};

function actionLabel(action: string) {
  return ACTION_LABELS[action] ?? action;
}

function actionGroup(action: string) {
  const prefix = action.split('.')[0];
  const groups: Record<string, string> = {
    secret: 'Security',
    integrations: 'Security',
    config: 'Settings',
    announcement: 'Messages',
    staff: 'Staff',
    farm: 'Farms',
    payment: 'Finance',
    users: 'Users',
    plan: 'Finance',
    smsPackage: 'Finance',
  };
  return groups[prefix] ?? 'Other';
}

export default function AuditPage() {
  const audit = useLoad(() => loadAudit(200));
  const [q, setQ] = useState('');
  const [group, setGroup] = useState('');

  const groups = Array.from(new Set((audit.data ?? []).map((e) => actionGroup(e.action)))).sort();

  const rows = (audit.data ?? []).filter((e) => {
    if (group && actionGroup(e.action) !== group) return false;
    if (!q) return true;
    const low = q.toLowerCase();
    return (
      e.action.includes(low) ||
      actionLabel(e.action).toLowerCase().includes(low) ||
      e.byName.toLowerCase().includes(low) ||
      e.target.toLowerCase().includes(low) ||
      (e.tenantId ?? '').toLowerCase().includes(low)
    );
  });

  function exportCsv() {
    downloadCsv('audit-log.csv', ['Time', 'Who', 'Action', 'Target', 'Details'], rows.map((e) => [date(e.at), e.byName, actionLabel(e.action), e.target, e.details ? JSON.stringify(e.details) : '']));
  }

  return (
    <Need perm="audit">
      <PageHead title="Audit log" subtitle="Every admin action, most recent first">
        <button className="btn sm outline" onClick={exportCsv} disabled={!rows.length}>
          <Icon name="export" /> Export CSV
        </button>
        <PrintButton />
      </PageHead>
      <div className="row wrap">
        <input
          className="input grow-field"
          placeholder="Search by person, action or target…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
        <select className="input" style={{ flex: '0 0 auto' }} value={group} onChange={(e) => setGroup(e.target.value)}>
          <option value="">All categories</option>
          {groups.map((g) => (
            <option key={g} value={g}>
              {g}
            </option>
          ))}
        </select>
      </div>

      <section className="stack">
        <div className="table-wrap">
          <table className="table rt">
            <thead>
              <tr>
                <th>Time</th>
                <th>Who</th>
                <th>Action</th>
                <th>Target</th>
                <th>Details</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((e) => (
                <tr key={e.id}>
                  <td className="mono small" data-label="Time" style={{ whiteSpace: 'nowrap' }}>
                    {date(e.at)}
                  </td>
                  <td data-label="Who">
                    <strong>{e.byName}</strong>
                  </td>
                  <td className="wide" data-label="Action">
                    <span className="chip">{actionGroup(e.action)}</span>{' '}
                    <span className="small">{actionLabel(e.action)}</span>
                  </td>
                  <td className="mono small wide" data-label="Target" style={{ whiteSpace: 'normal', overflowWrap: 'anywhere' }}>{e.target}</td>
                  <td className="small muted wide" data-label="Details" style={{ whiteSpace: 'normal' }}>
                    {e.details
                      ? Object.entries(e.details)
                          .slice(0, 3)
                          .map(([k, v]) => `${k}: ${typeof v === 'object' ? JSON.stringify(v) : v}`)
                          .join(' · ')
                      : '—'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {audit.data && !rows.length && <Empty>{q || group ? 'No matching entries.' : 'No audit entries yet.'}</Empty>}
        </div>
      </section>
    </Need>
  );
}
