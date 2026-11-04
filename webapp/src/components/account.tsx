'use client';

// Shown when a deleted account signs in again before the 90-day hold ends
// (decision 0024). Nothing can be recorded; support can restore it.

import { useRouter } from 'next/navigation';
import { Icon } from '@/components/Icon';
import { date } from '@/lib/format';
import { useSession } from '@/lib/session';
import { telHref, waHref } from '@/lib/site';
import { usePlatform } from '@/lib/usePlatform';

export function ClosedAccountScreen() {
  const { closed, signOut } = useSession();
  const { config } = usePlatform();
  const router = useRouter();
  const phone = config.support.phone;
  const wa = config.support.whatsapp || phone;
  return (
    <div className="full-screen closed-screen">
      <div className="card stack lg">
        <Icon name="lock" className="icon closed-icon" />
        <h2 className="pub-h2">This account was deleted</h2>
        <p className="muted">
          {closed?.restoreBy
            ? `Your records are kept until ${date(closed.restoreBy)}. To get your account back before then, contact FarmTap support.`
            : 'Your records are kept for 90 days. To get your account back, contact FarmTap support.'}
        </p>
        <div className="row wrap">
          <a className="btn" href={waHref(wa)} target="_blank" rel="noreferrer">
            <Icon name="whatsapp" /> WhatsApp support
          </a>
          <a className="btn outline" href={telHref(phone)}>
            <Icon name="phone" /> Call {phone}
          </a>
        </div>
        <button type="button" className="btn ghost" onClick={() => void signOut().then(() => router.replace('/'))}>
          Sign out
        </button>
      </div>
    </div>
  );
}
