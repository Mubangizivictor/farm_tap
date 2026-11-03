'use client';

import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { Loading } from '@/components/Loading';
import { useSession } from '@/lib/session';

/** Where to go after sign-in, if a page sent the person to sign in (the control panel). */
function takeNext(clear = false): string | null {
  try {
    const next = sessionStorage.getItem('farmtap.next');
    if (clear) sessionStorage.removeItem('farmtap.next');
    return next && next.startsWith('/admin/') ? next : null;
  } catch {
    return null;
  }
}

/** Start: signed-in people go straight to their farm (no sign-in again). */
export default function Start() {
  const { user, farms, farm } = useSession();
  const router = useRouter();
  useEffect(() => {
    if (user === null) router.replace('/sign-in/');
    else if (user && takeNext()) router.replace(takeNext(true)!);
    else if (user && farms !== undefined) router.replace(farm ? '/home/' : '/farms/');
  }, [user, farms, farm, router]);
  return <Loading />;
}
