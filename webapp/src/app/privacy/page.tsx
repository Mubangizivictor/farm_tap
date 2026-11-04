'use client';

// Public Privacy Policy (decision 0024): the latest version published in the
// control panel (Legal documents), or the built-in default.

import { LegalView, PublicShell } from '@/components/public';
import { loadLegal, useOnce } from '@/lib/publicData';

export default function Page() {
  const doc = useOnce(() => loadLegal('privacy'));
  return (
    <PublicShell wide={false}>
      <LegalView doc={doc} />
    </PublicShell>
  );
}
