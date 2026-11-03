'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useState, type ReactNode } from 'react';
import { Icon, type IconName } from '@/components/Icon';
import { Loading } from '@/components/Loading';
import { hasHerd, isCentre, manages, planState, type Farm } from '@/lib/domain';
import { date, initials } from '@/lib/format';
import { farmKind, planText } from '@/lib/labels';
import { useSession, useTheme, type ThemeChoice } from '@/lib/session';
import { supportWhatsAppLink } from '@/lib/support';

interface NavItem {
  href: string;
  label: string;
  icon: IconName;
}

/** The menu fits the farm: a centre sees suppliers, a farm sees its herd. */
function navFor(f: Farm): NavItem[] {
  return [
    { href: '/home/', label: 'Home', icon: 'home' as const },
    ...(hasHerd(f)
      ? [
          { href: '/milk/', label: 'Milk', icon: 'drop' as const },
          { href: '/herd/', label: 'Herd', icon: 'cow' as const },
          { href: '/health/', label: 'Health', icon: 'health' as const },
        ]
      : []),
    ...(isCentre(f) ? [{ href: '/farmers/', label: 'Suppliers', icon: 'truck' as const }] : []),
    { href: '/workers/', label: 'Workers', icon: 'workers' as const },
    ...(manages(f) ? [{ href: '/money/', label: 'Money', icon: 'money' as const }] : []),
    { href: '/settings/', label: 'Settings', icon: 'settings' as const },
  ];
}

function ThemeSwitch() {
  const [choice, setChoice] = useTheme();
  const opts: [ThemeChoice, string][] = [
    ['device', 'Device'],
    ['light', 'Light'],
    ['dark', 'Dark'],
  ];
  return (
    <div className="seg" role="group" aria-label="Theme">
      {opts.map(([v, label]) => (
        <button key={v} type="button" aria-pressed={choice === v} onClick={() => setChoice(v)}>
          {label}
        </button>
      ))}
    </div>
  );
}

function UserMenu() {
  const { user, farms, signOut } = useSession();
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const name = user?.displayName || user?.email || '';
  return (
    <div className="rel">
      <button className="icon-btn" aria-label="Account" aria-expanded={open} onClick={() => setOpen(!open)}>
        <span className="avatar">{user?.photoURL ? <img src={user.photoURL} alt="" referrerPolicy="no-referrer" /> : initials(name)}</span>
      </button>
      {open && (
        <div className="menu" role="menu" onMouseLeave={() => setOpen(false)}>
          <div className="stack" style={{ padding: 'var(--s-md) var(--s-lg)', gap: 'var(--s-xxs)' }}>
            <strong>{user?.displayName || 'Your account'}</strong>
            <span className="small muted">{user?.email}</span>
          </div>
          <div style={{ padding: 'var(--s-xs) var(--s-lg) var(--s-md)' }}>
            <ThemeSwitch />
          </div>
          {farms && farms.length > 1 && (
            <button role="menuitem" onClick={() => router.push('/farms/')}>
              <Icon name="switch" /> Switch place
            </button>
          )}
          <a role="menuitem" href={supportWhatsAppLink()} target="_blank" rel="noreferrer">
            <Icon name="whatsapp" /> Help on WhatsApp
          </a>
          <button role="menuitem" onClick={() => void signOut().then(() => router.replace('/sign-in/'))}>
            <Icon name="logout" /> Sign out
          </button>
        </div>
      )}
    </div>
  );
}

function Banners({ farm }: { farm: Farm }) {
  const { online } = useSession();
  const plan = planState(farm.subscription, new Date());
  return (
    <>
      {!online && (
        <div className="banner bad" role="status">
          <Icon name="offline" />
          <span className="grow">No internet. The web app needs the internet; saving is off until you are back online.</span>
        </div>
      )}
      {plan.kind === 'readOnly' && (
        <div className="banner warn" role="status">
          <Icon name="lock" />
          <span className="grow">
            {farm.subscription.paidUntil ? 'Your subscription has ended' : 'Your free trial has ended'}
            {plan.since ? ` (${date(plan.since)})` : ''}. You can still see everything, but new records are off.{' '}
            <a href={supportWhatsAppLink(`Hello FarmTap, I want to pay for ${farm.name}.`)} target="_blank" rel="noreferrer">
              Pay to continue
            </a>
          </span>
        </div>
      )}
      {plan.kind === 'grace' && (
        <div className="banner warn" role="status">
          <Icon name="alert" />
          <span className="grow">
            Payment is due. Recording stops in {plan.daysLeft} day{plan.daysLeft === 1 ? '' : 's'}.
          </span>
        </div>
      )}
    </>
  );
}

export default function FarmLayout({ children }: { children: ReactNode }) {
  const { user, farms, farm } = useSession();
  const router = useRouter();
  const path = usePathname();
  const [more, setMore] = useState(false);

  useEffect(() => {
    if (user === null) router.replace('/sign-in/');
    else if (user && farms !== undefined && !farm) router.replace('/farms/');
  }, [user, farms, farm, router]);

  useEffect(() => setMore(false), [path]);

  if (!user || !farm) return <Loading />;

  const nav = navFor(farm);
  const plan = planText(planState(farm.subscription, new Date()));
  const current = (href: string) => (path === href || path === href.slice(0, -1) ? 'page' : undefined);
  const phoneMain = nav.slice(0, 4);
  const phoneMore = nav.slice(4);

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="row" style={{ padding: 'var(--s-xs) var(--s-sm)' }}>
          <div className="logo-mark" aria-hidden />
          <strong className="brand-text">FarmTap</strong>
        </div>
        <nav className="nav" aria-label="Main">
          {nav.map((n) => (
            <Link key={n.href} href={n.href} aria-current={current(n.href)} title={n.label}>
              <Icon name={n.icon} />
              <span>{n.label}</span>
            </Link>
          ))}
        </nav>
        <div className="grow" />
        <div className="side-foot card flat small">
          <strong>{farm.name}</strong>
          <div className="muted">{farmKind(farm)}</div>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <div className="logo-mark show-sm-only" aria-hidden />
          <div className="stack grow" style={{ gap: 0 }}>
            <span className="farm-name">{farm.name}</span>
            <span className="small muted hide-sm">
              {farmKind(farm)}
              {farm.place ? ` · ${farm.place}` : ''}
            </span>
          </div>
          <Link href="/settings/" className={`chip ${plan.tone} hide-sm`} style={{ textDecoration: 'none' }}>
            {plan.text}
          </Link>
          <UserMenu />
        </header>
        <div className="content">
          <Banners farm={farm} />
          {children}
        </div>
      </div>

      {more && (
        <div className="more-sheet nav" role="menu">
          {phoneMore.map((n) => (
            <Link key={n.href} href={n.href} aria-current={current(n.href)}>
              <Icon name={n.icon} />
              <span>{n.label}</span>
            </Link>
          ))}
        </div>
      )}
      <nav className="bottomnav" aria-label="Main">
        {phoneMain.map((n) => (
          <Link key={n.href} href={n.href} aria-current={current(n.href)}>
            <Icon name={n.icon} />
            {n.label}
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
