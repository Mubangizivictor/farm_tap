'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useRef } from 'react';
import { doc, getDoc } from 'firebase/firestore';
import { Loading } from '@/components/Loading';
import { firebase } from '@/lib/firebase';
import { useSession } from '@/lib/session';

/** Where to go after sign-in, if a page sent the person to sign in (the control panel, the supplier pages). */
function takeNext(clear = false): string | null {
  try {
    const next = sessionStorage.getItem('farmtap.next');
    if (clear) sessionStorage.removeItem('farmtap.next');
    return next && /^\/(admin|supplier|supplier-invite)\//.test(next) ? next : null;
  } catch {
    return null;
  }
}

/** Start: signed-in people go straight to their farm (no sign-in again). */
export default function Start() {
  const { user, farms, farm } = useSession();
  const router = useRouter();
  // Read once: the effect below can run again before the page changes.
  const next = useRef<string | null | undefined>(undefined);
  useEffect(() => {
    if (next.current === undefined && user) next.current = takeNext(true);
    if (user === null) router.replace('/sign-in/');
    else if (user && next.current) router.replace(next.current);
    else if (user && farms !== undefined) {
      if (farm) return router.replace('/home/');
      if (farms.length > 0) return router.replace('/farms/');
      // No farm: a supplier who accepted an invite goes to their deliveries,
      // anyone else to set up a farm.
      let gone = false;
      getDoc(doc(firebase().db, 'users', user.uid))
        .then((s) => {
          const links = s.data()?.farmerLinks as unknown[] | undefined;
          if (!gone) router.replace(links?.length ? '/supplier/' : '/farms/');
        })
        .catch(() => !gone && router.replace('/farms/'));
      return () => {
        gone = true;
      };
    }
  }, [user, farms, farm, router]);
  return <Loading />;
}
