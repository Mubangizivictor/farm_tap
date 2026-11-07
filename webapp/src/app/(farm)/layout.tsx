'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useRef, useState, type ReactNode } from 'react';
import { Icon, type IconName } from '@/components/Icon';
import { SideHead, useSidebar } from '@/components/side';
import { Loading } from '@/components/Loading';
import { ClosedAccountScreen } from '@/components/account';
import { ToastProvider } from '@/components/ui';
import { hasHerd, isCentre, manages, planState, type Farm } from '@/lib/domain';
import { date } from '@/lib/format';
import { farmKind, planText } from '@/lib/labels';
import { featureOn, WEB_BUILD, type FeatureKey, type PlatformConfig } from '@/lib/platform';
import { useSession, useTheme, type ThemeChoice } from '@/lib/session';
import { supportWhatsAppLink } from '@/lib/support';
import { markFarmSeen, useIsPlatformAdmin } from '@/lib/adminSession';
import { usePlatform, PlatformProvider } from '@/lib/usePlatform';
import { Avatar } from '@/components/Avatar';

interface NavItem {
  href: string;
  label: string;
  icon: IconName;
  feature?: FeatureKey;
}

/** The menu fits the farm: a centre sees suppliers, a farm sees its herd. */
function navFor(f: Farm, cfg: PlatformConfig): NavItem[] {
  const feat = (k: FeatureKey) => featureOn(k, cfg.features, null, f.features as Record<FeatureKey, boolean | undefined>);
  return [
    { href: '/home/', label: 'Home', icon: 'home' as const },
    // AI Intelligence (decision 0025): second, so it is on the phone's bottom bar too.
    ...(feat('ai') && cfg.ai.enabled ? [{ href: '/ai/', label: 'AI Intelligence', icon: 'spark' as const }] : []),
    ...(hasHerd(f) && feat('milk') ? [{ href: '/milk/', label: 'Milk', icon: 'drop' as const }] : []),
    ...(hasHerd(f) && feat('herd') ? [{ href: '/herd/', label: 'Herd', icon: 'tag' as const }] : []),
    ...(hasHerd(f) && feat('health') ? [{ href: '/health/', label: 'Health', icon: 'health' as const }] : []),
    ...(hasHerd(f) && feat('breeding') ? [{ href: '/breeding/', label: 'Breeding', icon: 'cow' as const }] : []),
    ...(hasHerd(f) && feat('feeding') ? [{ href: '/feeds/', label: 'Feeds', icon: 'feed' as const }] : []),
    ...(isCentre(f) ? [{ href: '/farmers/', label: 'Milk suppliers', icon: 'truck' as const }] : []),
    ...(feat('workers') ? [{ href: '/workers/', label: 'Workers', icon: 'workers' as const }] : []),
    { href: '/roster/', label: 'Duty roster', icon: 'calendar' as const },
    { href: '/tasks/', label: 'Tasks', icon: 'check' as const },
    { href: '/contacts/', label: 'Contacts', icon: 'phone' as const },
    ...(manages(f) && feat('money') ? [{ href: '/money/', label: 'Money', icon: 'money' as const }] : []),
    ...(manages(f) && feat('money') ? [{ href: '/reports/', label: 'Reports', icon: 'chart' as const }] : []),
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
  const { user, canSwitch, signOut, photo } = useSession();
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const name = user?.displayName || user?.email || '';
  return (
    <div className="rel">
      <button className="icon-btn" aria-label="Account" aria-expanded={open} onClick={() => setOpen(!open)}>
        <Avatar photo={photo} name={name} />
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
          {canSwitch && (
            <button role="menuitem" onClick={() => router.push('/farms/')} title="Open another farm you own. Each farm keeps its own records, workers and plan.">
              <Icon name="switch" /> Switch farm
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

function MaintenanceScreen({ msg }: { msg: string }) {
  return (
    <div className="full-screen stack" style={{ alignItems: 'center', justifyContent: 'center', gap: 'var(--s-lg)', textAlign: 'center', padding: 'var(--s-xl)' }}>
      <Icon name="settings" className="icon" />
      <div className="stack" style={{ gap: 'var(--s-xs)' }}>
        <h2>FarmTap is under maintenance</h2>
        <p className="muted">{msg || 'We are making improvements. Please try again shortly.'}</p>
        <p className="small muted">Need help? Call {String(typeof window !== 'undefined' ? '' : '')} <a href="tel:+256793128137">+256 793 128 137</a></p>
      </div>
    </div>
  );
}

function DisabledScreen() {
  return (
    <div className="full-screen stack" style={{ alignItems: 'center', justifyContent: 'center', gap: 'var(--s-lg)', textAlign: 'center', padding: 'var(--s-xl)' }}>
      <Icon name="lock" className="icon" />
      <div className="stack" style={{ gap: 'var(--s-xs)' }}>
        <h2>Your account has been paused</h2>
        <p className="muted">Contact FarmTap support to find out more.</p>
        <p><a href="https://wa.me/256793128137" target="_blank" rel="noreferrer" className="btn">WhatsApp support</a></p>
        <p className="small muted">Or call <a href="tel:+256793128137">+256 793 128 137</a></p>
      </div>
    </div>
  );
}

function AnnouncementBanners({ farm }: { farm: Farm }) {
  const { farmAnnouncements } = usePlatform();
  const [dismissed, setDismissed] = useState<Set<string>>(new Set());
  const banners = farmAnnouncements(farm).filter((a) => !dismissed.has(a.id));
  if (!banners.length) return null;
  return (
    <>
      {banners.map((a) => (
        <div key={a.id} className={`banner ${a.level}`} role="status">
          <Icon name={a.level === 'warn' ? 'alert' : 'megaphone'} />
          <span className="grow">
            <strong>{a.title}</strong>{a.body ? ` ${a.body}` : ''}
          </span>
          <button className="icon-btn" aria-label="Dismiss" onClick={() => setDismissed((s) => new Set([...s, a.id]))}>
            <Icon name="close" />
          </button>
        </div>
      ))}
    </>
  );
}

function Banners({ farm }: { farm: Farm }) {
  const { online } = useSession();
  const { config } = usePlatform();
  const plan = planState(farm.subscription, new Date());
  const [refreshDismissed, setRefreshDismissed] = useState(false);
  const needsRefresh = WEB_BUILD > 0 && config.web.minBuild > WEB_BUILD && !refreshDismissed;

  return (
    <>
      <AnnouncementBanners farm={farm} />
      {needsRefresh && (
        <div className="banner warn" role="status">
          <Icon name="refresh" />
          <span className="grow">{config.web.message || 'A new version of FarmTap is available. Please refresh your browser.'}</span>
          <button className="btn sm" onClick={() => window.location.reload()}>Refresh</button>
          <button className="icon-btn" aria-label="Dismiss" onClick={() => setRefreshDismissed(true)}><Icon name="close" /></button>
        </div>
      )}
      {farm.closed && (
        <div className="banner bad" role="status">
          <Icon name="lock" />
          <span className="grow">This farm was closed by its owner. You can look at records but not add new ones.</span>
        </div>
      )}
      {farm.farmStatus === 'suspended' && (
        <div className="banner bad" role="status">
          <Icon name="pause" />
          <span className="grow">This farm has been suspended. Recording is off. Contact support to restore access.</span>
        </div>
      )}
      {!online && (
        <div className="banner bad" role="status">
          <Icon name="offline" />
          <span className="grow">No internet. The web app needs the internet; saving is off until you are back online.</span>
        </div>
      )}
      {plan.kind === 'readOnly' && (
        <div className="banner bad" role="status">
          <Icon name="lock" />
          <span className="grow">
            {farm.subscription.paidUntil ? 'Your plan has ended' : 'Your free trial has ended'}
            {plan.since ? ` (${date(plan.since)})` : ''}. Recording, cards and changes are off until you pay. You are viewing your records only.
          </span>
          <Link className="btn sm" href="/settings/#plan">
            See plans
          </Link>
        </div>
      )}
      {plan.kind === 'paid' && plan.daysLeft <= 5 && (
        <div className="banner warn" role="status">
          <Icon name="alert" />
          <span className="grow">
            Your plan ends in {plan.daysLeft} day{plan.daysLeft === 1 ? '' : 's'}. Pay before then so recording does not stop.
          </span>
          <Link className="btn sm outline" href="/settings/#plan">
            Pay now
          </Link>
        </div>
      )}
      {plan.kind === 'trial' && plan.daysLeft <= 3 && (
        <div className="banner warn" role="status">
          <Icon name="clock" />
          <span className="grow">
            {plan.daysLeft <= 0 ? 'Your free trial ends today.' : `Your free trial ends in ${plan.daysLeft} day${plan.daysLeft === 1 ? '' : 's'}.`} After that, nothing can be recorded until you pay.
          </span>
          <Link className="btn sm outline" href="/settings/#plan">
            See plans
          </Link>
        </div>
      )}
    </>
  );
}

/**
 * Shown on every page once the trial or plan has ended (decision 0023).
 * The server refuses every write by then; this tells people why and how to
 * pay. Owners and managers can still open their records to look at them.
 */
function LockScreen({ farm, onView }: { farm: Farm; onView: () => void }) {
  const plan = planState(farm.subscription, new Date());
  const boss = manages(farm);
  const since = plan.kind === 'readOnly' ? plan.since : null;
  return (
    <div className="lock-screen stack">
      <div className="lock-icon" aria-hidden>
        <Icon name="lock" />
      </div>
      <h1>{farm.subscription.paidUntil ? 'Your FarmTap plan has ended' : 'Your free trial has ended'}</h1>
      <p className="muted">
        {since ? `Since ${date(since)}, ` : ''}nothing can be added or changed on {farm.name}: no milk, animals, cards, scans, payments or workers. Your records are safe and
        nothing is deleted.
      </p>
      {boss ? (
        <div className="row wrap center">
          <Link className="btn lg" href="/settings/#plan">
            <Icon name="money" /> Choose a plan and pay
          </Link>
          <button className="btn outline" onClick={onView}>
            <Icon name="eye" /> Look at my records
          </button>
        </div>
      ) : (
        <p>Ask the farm owner to pay for FarmTap. Recording starts again as soon as the payment is confirmed.</p>
      )}
      <p className="small muted">
        Need help paying? <a href={supportWhatsAppLink(`Hello FarmTap, I want to pay for ${farm.name}.`)} target="_blank" rel="noreferrer">WhatsApp FarmTap support</a>
      </p>
    </div>
  );
}

function FarmShell({ children }: { children: ReactNode }) {
  const { user, farms, farm, online, closed } = useSession();
  const { config } = usePlatform();
  const router = useRouter();
  const path = usePathname();
  const [more, setMore] = useState(false);
  const isAdmin = useIsPlatformAdmin();
  const seenRef = useRef(false);
  const side = useSidebar();
  const [viewing, setViewing] = useState(false);

  useEffect(() => {
    if (user === null) router.replace('/sign-in/');
    else if (user && farms !== undefined && !farm) router.replace('/farms/');
  }, [user, farms, farm, router]);

  useEffect(() => setMore(false), [path]);

  // Mark this farm as seen by the current user (admin analytics)
  useEffect(() => {
    if (farm && !seenRef.current) {
      seenRef.current = true;
      markFarmSeen(farm.id);
    }
  }, [farm]);

  if (user && closed) return <ClosedAccountScreen />;
  if (!user || !farm) return <Loading />;

  // Maintenance mode: admins bypass
  if (config.maintenance.on && !isAdmin) {
    return <MaintenanceScreen msg={config.maintenance.message} />;
  }

  // Disabled account
  const firebaseUser = user as { disabled?: boolean };
  if (firebaseUser.disabled) {
    return <DisabledScreen />;
  }

  const nav = navFor(farm, config);
  const state = planState(farm.subscription, new Date());
  const plan = planText(state);
  const locked = state.kind === 'readOnly' && !path.startsWith('/settings') && !(viewing && manages(farm));
  const current = (href: string) => (path === href || path === href.slice(0, -1) || (href === '/ai/' && path.startsWith('/ai/')) ? 'page' : undefined);
  const phoneMain = nav.slice(0, 4);
  const phoneMore = nav.slice(4);

  return (
    <div className={`shell farm ${side.closed ? 'side-closed' : ''}`}>
      <aside className="sidebar">
        <SideHead home="/home/" closed={side.closed} onToggle={side.toggle} />
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
          <span className={`sync-dot hide-sm ${online ? '' : 'off'}`} title={online ? 'Changes from the farm phones show here as they sync' : 'No internet'}>
            {online ? 'Live' : 'Offline'}
          </span>
          <Link href="/settings/#plan" className={`chip plan-chip ${plan.tone}`} title="See plans and pay">
            <Icon name={state.kind === 'readOnly' ? 'lock' : 'clock'} />
            <span>{plan.text}</span>
          </Link>
          <UserMenu />
        </header>
        <div className="content">
          <Banners farm={farm} />
          {locked ? <LockScreen farm={farm} onView={() => setViewing(true)} /> : children}
        </div>
      </div>

      {more && <div className="drawer-scrim more-scrim" onClick={() => setMore(false)} aria-hidden />}
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

export default function FarmLayout({ children }: { children: ReactNode }) {
  return (
    <PlatformProvider>
      <ToastProvider>
        <FarmShell>{children}</FarmShell>
      </ToastProvider>
    </PlatformProvider>
  );
}
