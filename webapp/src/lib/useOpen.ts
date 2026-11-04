'use client';

import { useEffect, useState } from 'react';

/**
 * A dialog that opens from a link such as /milk/?new=1 (Home quick
 * actions). The query is removed after opening so Back and refresh behave.
 */
export function useOpenFromUrl(key = 'new'): [boolean, (v: boolean) => void] {
  const [open, setOpen] = useState(false);
  useEffect(() => {
    const url = new URL(window.location.href);
    if (url.searchParams.has(key)) {
      setOpen(true);
      url.searchParams.delete(key);
      history.replaceState(null, '', url.pathname + url.search + url.hash);
    }
  }, [key]);
  return [open, setOpen];
}
