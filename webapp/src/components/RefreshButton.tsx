'use client';

import { Icon } from '@/components/Icon';
import { useRefresh } from '@/lib/refresh';

/** Top-bar refresh: reloads everything on the page and shows the FarmTap logo for 1.5 s. */
export function RefreshButton() {
  const { refresh, refreshing } = useRefresh();
  return (
    <button className="icon-btn" aria-label="Refresh" title="Refresh" disabled={refreshing} onClick={() => void refresh()}>
      <Icon name="refresh" className={refreshing ? 'spin' : undefined} />
    </button>
  );
}
