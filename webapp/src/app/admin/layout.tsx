'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useState, type ReactNode } from 'react';
import { Icon, type IconName } from '@/components/Icon';
import { SideHead, useSidebar } from '@/components/side';
import { Loading } from '@/components/Loading';
import { AdminProvider, useAdmin } from '@/lib/adminSession';
import type { Permission } from '@/lib/platform';
import { useSession } from '@/lib/session';
import { Avatar } from '@/components/Avatar';

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
  { href: '/admin/refunds/', label: 'Receipts and refunds', icon: 'receipt', any: ['finance'], group: 'Business' },
  { href: '/admin/users/', label: 'Users', icon: 'workers', any: ['users', 'support'], group: 'People' },
  { href: '/admin/deletions/', label: 'Deleted accounts', icon: 'refresh', any: ['users', 'support'], group: 'People' },
  { href: '/admin/announce/', label: 'Announcements', icon: 'megaphone', any: ['messages'], group: 'People' },
  { href: '/admin/staff/', label: 'Admin staff', icon: 'shield', any: ['staff'], group: 'People' },
  { href: '/admin/settings/', label: 'App settings', icon: 'settings', any: ['settings'], group: 'Platform' },
  { href: '/admin/integrations/', label: 'APIs and keys', icon: 'key', any: ['settings', 'secrets'], group: 'Platform' },
  { href: '/admin/ai/', label: 'AI Control Centre', icon: 'spark', any: ['settings', 'farms', 'support'], group: 'Platform' },
  { href: '/admin/branding/', label: 'Brand and documents', icon: 'edit', any: ['settings'], group: 'Platform' },
  { href: '/admin/legal/', label: 'Legal documents', icon: 'shield', any: ['settings'], group: 'Platform' },
  { href: '/admin/website/', label: 'Website', icon: 'globe', any: ['settings'], group: 'Platform' },
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
          <button className="btn ghost sm" onClick={() => router.push('/start/')}>
            Back to my farm
          </button>
          <button className="btn ghost sm" onClick={() => void signOut().then(() => router.replace('/admin-sign-in/'))}>
            <Icon name="logout" /> Sign out
          </button>
        </div>
      </div>
    </div>
  );
}

/** Bottom of the sidebar: who is signed in, and whose platform this is (one place, not the top bar). */
function SideFoot({ name, access, photo, drawer }: { name: string; access: string; photo: string | null; drawer?: boolean }) {
  return (
    <div className={`${drawer ? '' : 'side-foot '}card flat small side-who`}>
      <div className="row" style={{ gap: 'var(--s-md)', minWidth: 0 }}>
        <Avatar photo={photo} name={name} />
        <div className="stack" style={{ gap: 0, minWidth: 0 }}>
          <strong className="ellipsis">{name}</strong>
          <span className="muted ellipsis">{access}</span>
        </div>
      </div>
      <div className="muted side-platform">FarmTap platform · Victorbee Technologies</div>
    </div>
  );
}

function NavLinks({ items, current }: { items: NavItem[]; current: (href: string) => 'page' | undefined }) {
  const groups = [...new Set(items.map((i) => i.group))];
  return (
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
  );
}

function Shell({ children }: { children: ReactNode }) {
  const { user, signOut, online, photo } = useSession();
  const { me } = useAdmin();
  const path = usePathname();
  const router = useRouter();
  const [drawer, setDrawer] = useState(false);
  const [userMenu, setUserMenu] = useState(false);
  const [signingOut, setSigningOut] = useState(false);
  const side = useSidebar();
  useEffect(() => {
    setDrawer(false);
    setUserMenu(false);
  }, [path]);
  useEffect(() => {
    if (!drawer && !userMenu) return;
    const esc = (e: KeyboardEvent) => e.key === 'Escape' && (setDrawer(false), setUserMenu(false));
    window.addEventListener('keydown', esc);
    return () => window.removeEventListener('keydown', esc);
  }, [drawer, userMenu]);

  async function handleSignOut() {
    setSigningOut(true);
    setUserMenu(false);
    await signOut();
    router.replace('/admin-sign-in/');
  }

  if (me === undefined) return <Loading />;
  if (!me || !me.active) return <NotStaff />;

  const items = nav.filter((n) => n.any.length === 0 || me.role === 'owner' || n.any.some((p) => me.perms.includes(p)));
  const current = (href: string) => (path === href || path === href.slice(0, -1) || (href === '/admin/farms/' && path.startsWith('/admin/farm')) ? 'page' : undefined);
  const here = items.find((n) => current(n.href));
  const quick = items.slice(0, 4);

  return (
    <div className={`shell admin ${side.closed ? 'side-closed' : ''}`}>
      <aside className="sidebar">
        <SideHead home="/admin/" closed={side.closed} onToggle={side.toggle} />
        <NavLinks items={items} current={current} />
        <div className="grow" />
        <SideFoot name={me.name || user?.email || ''} access={me.role === 'owner' ? 'Owner, full access' : `${me.role}: ${me.perms.length} areas`} photo={photo} />
      </aside>

      <div className="main">
        <header className="topbar">
          <button className="icon-btn menu-btn" aria-label="Open menu" aria-expanded={drawer} onClick={() => setDrawer(true)}>
            <Icon name="menu" />
          </button>
          <div className="grow" style={{ minWidth: 0 }}>
            <span className="farm-name">
              Control panel<span className="show-sm-only">{here && here.href !== '/admin/' ? ` · ${here.label}` : ''}</span>
            </span>
          </div>
          <span className="admin-badge">
            <Icon name="shield" className="icon" /> Admin
          </span>
          <Link href="/start/" className="btn sm outline hide-sm" title="Open my farm">
            My farm
          </Link>
          <div className="rel">
            <button className="icon-btn" aria-label="Account menu" aria-expanded={userMenu} title={me.name || user?.email || ''} onClick={() => setUserMenu((v) => !v)}>
              <Avatar photo={photo} name={me.name || user?.email || ''} />
            </button>
            {userMenu && (
              <>
                <div className="drawer-scrim" style={{ background: 'transparent' }} onClick={() => setUserMenu(false)} aria-hidden />
                <div className="menu" role="menu" style={{ zIndex: 62 }}>
                  <div className="stack" style={{ gap: 0, padding: 'var(--s-md) var(--s-lg)' }}>
                    <strong>{me.name || user?.email}</strong>
                    <span className="small muted">{user?.email}</span>
                  </div>
                  <Link href="/start/" role="menuitem">
                    <Icon name="home" /> My farm
                  </Link>
                  <button role="menuitem" disabled={signingOut} onClick={() => void handleSignOut()}>
                    <Icon name="logout" /> {signingOut ? 'Signing out…' : 'Sign out'}
                  </button>
                </div>
              </>
            )}
          </div>
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

      {drawer && (
        <>
          <div className="drawer-scrim" onClick={() => setDrawer(false)} aria-hidden />
          <aside className="drawer" role="dialog" aria-modal="true" aria-label="Menu">
            <div className="row between">
              <div className="row">
                <div className="logo-mark" aria-hidden />
                <strong>FarmTap</strong>
              </div>
              <button className="icon-btn" aria-label="Close menu" onClick={() => setDrawer(false)}>
                <Icon name="close" />
              </button>
            </div>
            <NavLinks items={items} current={current} />
            <div className="grow" />
            <SideFoot name={me.name || user?.email || ''} access={me.role === 'owner' ? 'Owner, full access' : `${me.role}: ${me.perms.length} areas`} photo={photo} drawer />
          </aside>
        </>
      )}
      <nav className="bottomnav" aria-label="Control panel shortcuts">
        {quick.map((n) => (
          <Link key={n.href} href={n.href} aria-current={current(n.href)}>
            <Icon name={n.icon} />
            {n.label.split(' ')[0]}
          </Link>
        ))}
        <button onClick={() => setDrawer(true)} aria-expanded={drawer}>
          <Icon name="menu" />
          Menu
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
      router.replace('/admin-sign-in/');
    }
  }, [user, router]);
  if (!user) return <Loading />;
  return (
    <AdminProvider>
      <Shell>{children}</Shell>
    </AdminProvider>
  );
}
