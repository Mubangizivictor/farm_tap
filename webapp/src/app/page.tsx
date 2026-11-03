'use client';

import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { Loading } from '@/components/Loading';
import { useSession } from '@/lib/session';

/** Start: signed-in people go straight to their farm (no sign-in again). */
export default function Start() {
  const { user, farms, farm } = useSession();
  const router = useRouter();
  useEffect(() => {
    if (user === null) router.replace('/sign-in/');
    else if (user && farms !== undefined) router.replace(farm ? '/home/' : '/farms/');
  }, [user, farms, farm, router]);
  return <Loading />;
}
