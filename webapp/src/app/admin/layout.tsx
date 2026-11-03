'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useState, type ReactNode } from 'react';
import { Icon, type IconName } from '@/components/Icon';
import { Loading } from '@/components/Loading';
import { AdminProvider, useAdmin } from '@/lib/adminSession';
import { initials } from '@/lib/format';
import type { Permission } from '@/lib/platform';
import { useSession } from '@/lib/session';

interface NavItem {
  href: string;
  label: string;
  icon: IconName;
  any: Permission[];
  group: string;
}

const nav: NavItem[] = [
  { href: '/admin/', label: 'Overview', icon: 'chart', any: [], group: 'Business' },
  { href: '/admin/farms/', label: 'Farms', icon: 'home', any: ['farms', 'support', 'finance', 'users'], group: 'Business' },
  { href: '/admin/money/', label: 'Payments', icon: 'receipt', any: ['finance'], group: 'Business' },
  { href: '/admin/plans/', label: 'Plans and SMS', icon: 'tag', any: ['finance'], group: 'Business' },
  { href: '/admin/users/', label: 'Users', icon: 'workers', any: ['users', 'support'], group: 'People' },
  { href: '/admin/announce/', label: 'Announcements', icon: 'megaphone', any: ['messages'], group: 'People' },
  { href: '/admin/staff/', label: 'Admin staff', icon: 'shield', any: ['staff'], group: 'People' },
  { href: '/admin/settings/', label: 'App settings', icon: 'settings', any: ['settings'], group: 'Platform' },
  { href: '/admin/integrations/', label: 'APIs and keys', icon: 'key', any: ['settings', 'secrets'], group: 'Platform' },
  { href: '/admin/audit/', label: 'Audit log', icon: 'list', any: ['audit'], group: 'Platform' },
];

function NotStaff() {
  const { user, signOut } = useSession();
  const { invite, acceptInvite } = useAdmin();
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');
  const [copied, setCopied] = useState(false);
  return (
    <div className="full-screen">
      <div className="box">
        <div className="logo-mark lg" aria-hidden />
        <h1>FarmTap control panel</h1>
        {invite ? (
          <>
            <p className="muted">You have been invited to the FarmTap team. Accept to open the control panel.</p>
            {err && <div className="banner bad">{err}</div>}
            <button
              className="btn block"
              disabled={busy}
              onClick={async () => {
                setBusy(true);
                setErr('');
                try {
                  await acceptInvite();
                } catch {
                  setErr('Could not accept. Your email must be verified; sign in with Google, or ask the owner to send the invite again.');
                } finally {
                  setBusy(false);
                }
              }}
            >
              <Icon name="check" /> Accept invite
            </button>
          </>
        ) : (
          <>
            <p className="muted">This account is not on the FarmTap team. Ask the owner to invite {user?.email || 'your email'}.</p>
            <div className="card flat stack" style={{ width: '100%' }}>
              <span className="small muted">Your account ID (the owner needs it to set up the first admin):</span>
              <div className="row between">
                <code className="mono">{user?.uid}</code>
                <button
                  className="btn sm outline"
                  onClick={() => {
                    void navigator.clipboard?.writeText(user?.uid ?? '');
                    setCopied(true);
                  }}
                >
                  <Icon name="copy" /> {copied ? 'Copied' : 'Copy'}
                </button>
              </div>
            </div>
          </>
        )}
        <div className="row">
          <button className="btn ghost sm" onClick={() => router.push('/')}>
            Back to my farm
          </button>
          <button className="btn ghost sm" onClick={() => void signOut().then(() => router.replace('/sign-in/'))}>
            <Icon name="logout" /> Sign out
          </button>
        </div>
      </div>
    </div>
  );
}

function Shell({ children }: { children: ReactNode }) {
  const { user, signOut, online } = useSession();
  const { me } = useAdmin();
  const path = usePathname();
  const router = useRouter();
  const [more, setMore] = useState(false);
  useEffect(() => setMore(false), [path]);

  if (me === undefined) return <Loading />;
  if (!me || !me.active) return <NotStaff />;

  const items = nav.filter((n) => n.any.length === 0 || me.role === 'owner' || n.any.some((p) => me.perms.includes(p)));
  const current = (href: string) => (path === href || path === href.slice(0, -1) ? 'page' : undefined);
  const groups = [...new Set(items.map((i) => i.group))];

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="row" style={{ padding: 'var(--s-xs) var(--s-sm)' }}>
          <div className="logo-mark" aria-hidden />
          <strong className="brand-text">FarmTap</strong>
        </div>
        <nav className="nav" aria-label="Control panel">
          {groups.map((g) => (
            <div key={g} className="stack" style={{ gap: 'var(--s-xxs)' }}>
              <div className="nav-group">{g}</div>
              {items
                .filter((i) => i.group === g)
                .map((n) => (
                  <Link key={n.href} href={n.href} aria-current={current(n.href)} title={n.label}>
                    <Icon name={n.icon} />
                    <span>{n.label}</span>
                  </Link>
                ))}
            </div>
          ))}
        </nav>
        <div className="grow" />
        <div className="side-foot card flat small">
          <strong>{me.name || user?.email}</strong>
          <div className="muted">{me.role === 'owner' ? 'Owner, full access' : `${me.role}: ${me.perms.length} areas`}</div>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div className="logo-mark show-sm-only" aria-hidden />
          <div className="stack grow" style={{ gap: 0 }}>
            <span className="farm-name">Control panel</span>
            <span className="small muted hide-sm">FarmTap platform, Victorbee Technologies</span>
          </div>
          <span className="admin-badge">
            <Icon name="shield" className="icon" /> Admin
          </span>
          <Link href="/" className="btn sm outline hide-sm" title="Open my farm">
            My farm
          </Link>
          <button className="icon-btn" aria-label="Sign out" title="Sign out" onClick={() => void signOut().then(() => router.replace('/sign-in/'))}>
            <span className="avatar">{initials(me.name || user?.email || '')}</span>
          </button>
        </header>
        <div className="content">
          {!online && (
            <div className="banner bad" role="status">
              <Icon name="offline" />
              <span className="grow">No internet. The control panel needs the internet; changes are off.</span>
            </div>
          )}
          {children}
        </div>
      </div>

      {more && (
        <div className="more-sheet nav" role="menu">
          {items.slice(4).map((n) => (
            <Link key={n.href} href={n.href} aria-current={current(n.href)}>
              <Icon name={n.icon} />
              <span>{n.label}</span>
            </Link>
          ))}
        </div>
      )}
      <nav className="bottomnav" aria-label="Control panel">
        {items.slice(0, 4).map((n) => (
          <Link key={n.href} href={n.href} aria-current={current(n.href)}>
            <Icon name={n.icon} />
            {n.label.split(' ')[0]}
          </Link>
        ))}
        <button onClick={() => setMore(!more)} aria-expanded={more}>
          <Icon name="more" />
          More
        </button>
      </nav>
    </div>
  );
}

export default function AdminLayout({ children }: { children: ReactNode }) {
  const { user } = useSession();
  const router = useRouter();
  useEffect(() => {
    if (user === null) {
      try {
        sessionStorage.setItem('farmtap.next', '/admin/');
      } catch {
        /* ignore */
      }
      router.replace('/sign-in/');
    }
  }, [user, router]);
  if (!user) return <Loading />;
  return (
    <AdminProvider>
      <Shell>{children}</Shell>
    </AdminProvider>
  );
}
