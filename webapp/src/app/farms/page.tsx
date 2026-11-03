'use client';

import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { Icon } from '@/components/Icon';
import { Loading } from '@/components/Loading';
import { planState } from '@/lib/domain';
import { initials } from '@/lib/format';
import { farmKind, planText, roleName } from '@/lib/labels';
import { useSession } from '@/lib/session';
import { supportWhatsAppLink } from '@/lib/support';

/**
 * Which farm to open. Most accounts have one farm and never see this page
 * (it opens straight into the farm). It shows only for an account that is
 * on more than one farm, or on none yet.
 */
export default function Farms() {
  const { user, farms, farmsError, openFarm, signOut, reloadFarms } = useSession();
  const router = useRouter();

  useEffect(() => {
    if (user === null) router.replace('/sign-in/');
  }, [user, router]);

  if (!user || farms === undefined) return <Loading />;

  const now = new Date();
  const name = user.displayName || user.email || '';

  return (
    <div className="auth-main">
      <div className="auth-box">
        <div className="auth-brand">
          <div className="logo-mark lg" aria-hidden />
          <h1>{farms.length ? `Welcome back${user.displayName ? `, ${user.displayName.split(' ')[0]}` : ''}` : 'Set up your farm'}</h1>
          <p className="muted">
            {farms.length
              ? 'Your account is on more than one place. Choose where to work today.'
              : 'Your account is not on a farm yet. Set up your farm now, or ask the owner to add you as a manager.'}
          </p>
        </div>

        {farmsError && (
          <div className="banner bad">
            <Icon name="offline" />
            <span className="grow">Could not load your farms. Check the internet.</span>
            <button className="btn sm outline" onClick={() => void reloadFarms()}>
              Try again
            </button>
          </div>
        )}

        {farms.map((f) => {
          const plan = planText(planState(f.subscription, now));
          return (
            <button
              key={f.id}
              className="card row"
              style={{ cursor: 'pointer', textAlign: 'left' }}
              onClick={() => {
                openFarm(f.id);
                router.push('/home/');
              }}
            >
              <div className="avatar lg">{initials(f.name)}</div>
              <div className="stack grow" style={{ gap: 'var(--s-xxs)' }}>
                <strong>{f.name}</strong>
                <span className="small muted">
                  {farmKind(f)}
                  {f.place ? ` · ${f.place}` : ''}
                </span>
                <div className="row wrap">
                  <span className="chip brand">{roleName(f)}</span>
                  <span className={`chip ${plan.tone}`}>{plan.text}</span>
                </div>
              </div>
              <Icon name="chevron" />
            </button>
          );
        })}

        {farms.length === 0 && !farmsError && (
          <button className="btn block" onClick={() => router.push('/setup/')}>
            <Icon name="plus" /> Set up my farm
          </button>
        )}

        <div className="row between wrap small">
          <span className="muted">Signed in as {name}</span>
          <button className="btn ghost sm" onClick={() => void signOut().then(() => router.replace('/sign-in/'))}>
            <Icon name="logout" /> Sign out
          </button>
        </div>
        <p className="small muted" style={{ textAlign: 'center' }}>
          Wrong account or need help? <a href={supportWhatsAppLink()}>WhatsApp FarmTap</a>
        </p>
      </div>
    </div>
  );
}
