'use client';

import { doc } from 'firebase/firestore';
import { useState, type FormEvent } from 'react';
import { MsgBanner, Need, useAction, useLoad } from '@/components/admin';
import { Icon } from '@/components/Icon';
import { Dialog, Empty, PageHead } from '@/components/ui';
import { adminChange, loadInvites, loadStaff, setOp, updateOp, type AdminStaff } from '@/lib/admin';
import { useAdmin } from '@/lib/adminSession';
import { firebase } from '@/lib/firebase';
import { initials } from '@/lib/format';
import { permissionList, rolePresets, type Permission } from '@/lib/platform';

function PermPicker({ role, perms, onChange }: { role: string; perms: Permission[]; onChange: (role: string, perms: Permission[]) => void }) {
  return (
    <div className="stack">
      <label className="field">
        <span>Role</span>
        <select className="input" value={role} onChange={(e) => onChange(e.target.value, e.target.value === 'custom' ? perms : rolePresets[e.target.value].perms)}>
          {Object.entries(rolePresets).map(([k, v]) => (
            <option key={k} value={k}>
              {v.label}
            </option>
          ))}
        </select>
      </label>
      <div className="list">
        {permissionList.map((p) => (
          <label key={p.key} className="toggle">
            <span className="t-text">
              <strong>{p.label}</strong>
              <span className="small muted">{p.hint}</span>
            </span>
            <input
              type="checkbox"
              role="switch"
              checked={perms.includes(p.key)}
              onChange={(e) => onChange('custom', e.target.checked ? [...perms, p.key] : perms.filter((x) => x !== p.key))}
            />
          </label>
        ))}
      </div>
      {perms.includes('secrets') && <div className="banner warn">API keys: this person can replace payment and SMS keys. Give it only to someone you trust with money.</div>}
    </div>
  );
}

function Invite({ onClose, onSaved }: { onClose: () => void; onSaved: () => void }) {
  const { actor } = useAdmin();
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [role, setRole] = useState('support');
  const [perms, setPerms] = useState<Permission[]>(rolePresets.support.perms);
  const act = useAction();
  function save(e: FormEvent) {
    e.preventDefault();
    const id = email.trim().toLowerCase();
    void act
      .run(() => adminChange(actor, { action: 'staff.invite', target: `adminInvites/${id}`, details: { role, perms } }, [setOp(doc(firebase().db, 'adminInvites', id), { role, perms, active: true, name: name.trim(), invitedBy: actor.name }, false)]))
      .then((ok) => ok && (onSaved(), onClose()));
  }
  return (
    <Dialog title="Invite staff" onClose={onClose}>
      <form className="stack" onSubmit={save}>
        <label className="field">
          <span>Their Google or email sign-in address</span>
          <input className="input" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
        </label>
        <label className="field">
          <span>Name</span>
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} />
        </label>
        <PermPicker role={role} perms={perms} onChange={(r, p) => (setRole(r), setPerms(p))} />
        <MsgBanner msg={act.msg?.ok ? null : act.msg} />
        <p className="small muted">Then send them the link: farmtap.victorbee.com/admin. They sign in with this address and press Accept.</p>
        <div className="actions">
          <button type="button" className="btn outline" onClick={onClose}>
            Cancel
          </button>
          <button className="btn" disabled={act.busy}>
            Send invite
          </button>
        </div>
      </form>
    </Dialog>
  );
}

function Edit({ s, onClose, onSaved }: { s: AdminStaff; onClose: () => void; onSaved: () => void }) {
  const { actor } = useAdmin();
  const [role, setRole] = useState(s.role);
  const [perms, setPerms] = useState<Permission[]>(s.perms);
  const act = useAction();
  return (
    <Dialog title={`Edit ${s.name || s.email}`} onClose={onClose}>
      <PermPicker role={role} perms={perms} onChange={(r, p) => (setRole(r), setPerms(p))} />
      <MsgBanner msg={act.msg?.ok ? null : act.msg} />
      <div className="actions">
        <button className="btn outline" onClick={onClose}>
          Cancel
        </button>
        <button
          className="btn"
          disabled={act.busy}
          onClick={() =>
            void act
              .run(() => adminChange(actor, { action: 'staff.edit', target: `platformAdmins/${s.uid}`, details: { role, perms } }, [updateOp(doc(firebase().db, 'platformAdmins', s.uid), { role, perms })]))
              .then((ok) => ok && (onSaved(), onClose()))
          }
        >
          Save
        </button>
      </div>
    </Dialog>
  );
}

export default function Staff() {
  const { actor, me } = useAdmin();
  const staff = useLoad(loadStaff);
  const invites = useLoad(loadInvites);
  const act = useAction();
  const [inviting, setInviting] = useState(false);
  const [editing, setEditing] = useState<AdminStaff | null>(null);

  const setActive = (s: AdminStaff, active: boolean) =>
    act.run(() => adminChange(actor, { action: active ? 'staff.on' : 'staff.off', target: `platformAdmins/${s.uid}` }, [updateOp(doc(firebase().db, 'platformAdmins', s.uid), { active })]), active ? 'Turned on.' : 'Turned off. They can no longer open the panel.').then(staff.reload);

  return (
    <Need perm="staff">
      <PageHead title="Admin staff" subtitle="Who can open this control panel, and what each person may do">
        <button className="btn sm" onClick={() => setInviting(true)}>
          <Icon name="plus" /> Invite staff
        </button>
      </PageHead>
      <MsgBanner msg={act.msg} />
      <div className="table-wrap">
        <table className="table rt">
          <thead>
            <tr>
              <th>Person</th>
              <th>Role</th>
              <th>Can do</th>
              <th>Status</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {(staff.data ?? []).map((s) => (
              <tr key={s.uid}>
                <td className="lead">
                  <div className="row">
                    <span className="avatar">{initials(s.name || s.email)}</span>
                    <div className="stack" style={{ gap: 0 }}>
                      <strong>{s.name || 'No name'}</strong>
                      <span className="small muted">{s.email}</span>
                    </div>
                  </div>
                </td>
                <td data-label="Role">{s.role === 'owner' ? 'Owner' : (rolePresets[s.role]?.label ?? s.role)}</td>
                <td style={{ whiteSpace: 'normal' }} className="small wide" data-label="Can do">
                  {s.role === 'owner' ? 'Everything' : s.perms.map((p) => permissionList.find((x) => x.key === p)?.label ?? p).join(', ') || 'Nothing'}
                </td>
                <td data-label="Status">{s.active ? <span className="chip ok">On</span> : <span className="chip">Off</span>}</td>
                <td className="r acts">
                  {s.role !== 'owner' && s.uid !== me?.uid && (
                    <div className="row" style={{ justifyContent: 'flex-end' }}>
                      <button className="btn sm outline" onClick={() => setEditing(s)}>
                        Edit
                      </button>
                      <button className="btn sm ghost" disabled={act.busy} onClick={() => void setActive(s, !s.active)}>
                        {s.active ? 'Turn off' : 'Turn on'}
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <section className="card">
        <div className="card-head">
          <h2>Invites waiting</h2>
        </div>
        <div className="list">
          {(invites.data ?? [])
            .filter((i) => i.active && !(staff.data ?? []).some((s) => s.email === i.email))
            .map((i) => (
              <div key={i.email} className="list-row wrap">
                <span className="grow-field" style={{ minWidth: 0, overflowWrap: 'anywhere' }}>
                  <strong>{i.name || i.email}</strong> <span className="small muted">{i.email}</span>
                </span>
                <span className="chip">{rolePresets[i.role]?.label ?? i.role}</span>
                <button
                  className="btn sm ghost"
                  disabled={act.busy}
                  onClick={() =>
                    void act
                      .run(() => adminChange(actor, { action: 'staff.cancelInvite', target: `adminInvites/${i.email}` }, [setOp(doc(firebase().db, 'adminInvites', i.email), { active: false, role: i.role }, true)]), 'Invite cancelled.')
                      .then(invites.reload)
                  }
                >
                  Cancel
                </button>
              </div>
            ))}
          {invites.data && !invites.data.some((i) => i.active) && <Empty>No invites waiting.</Empty>}
        </div>
      </section>
      <p className="small muted">The owner account is set once in the database console and cannot be changed or removed from here. Nobody can change their own access.</p>

      {inviting && <Invite onClose={() => setInviting(false)} onSaved={invites.reload} />}
      {editing && <Edit s={editing} onClose={() => setEditing(null)} onSaved={staff.reload} />}
    </Need>
  );
}
