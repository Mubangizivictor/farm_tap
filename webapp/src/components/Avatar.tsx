'use client';

// A person's picture. When there is no photo (or it fails to load) a plain
// head-and-shoulders avatar is shown instead, so nobody is ever a blank circle.

import { useEffect, useState } from 'react';

export function Avatar({ photo, name, size }: { photo?: string | null; name?: string | null; size?: 'lg' | 'xl' }) {
  const [broken, setBroken] = useState(false);
  useEffect(() => setBroken(false), [photo]);
  const cls = size === 'xl' ? 'avatar-xl' : `avatar${size ? ` ${size}` : ''}`;
  return (
    <span className={`${cls} person`} title={name ?? undefined} aria-hidden>
      {photo && !broken ? (
        <img src={photo} alt="" referrerPolicy="no-referrer" onError={() => setBroken(true)} />
      ) : (
        <svg className="avatar-default" viewBox="0 0 40 40" aria-hidden focusable="false">
          <circle cx="20" cy="15" r="7.5" />
          <path d="M5.5 37c1.6-8 7.4-12.5 14.5-12.5S32.9 29 34.5 37z" />
        </svg>
      )}
    </span>
  );
}
