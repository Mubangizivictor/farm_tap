'use client';

import { Children, isValidElement, useEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react';
import { fitPresets, rowSizes, type FitKind } from '@/lib/fit';

/**
 * Even grid: items share rows evenly for the space they have (see lib/fit).
 * One item is full width; 2 to 4 share a row; leftovers stretch, so no row
 * leaves an empty column. Columns follow the container's width, not the
 * screen's, so the same grid works in a page, a card or a dialog.
 */
export function Fit({ kind = 'cards', cols, children, className = '' }: { kind?: FitKind; cols?: readonly number[]; children: ReactNode; className?: string }) {
  const items = Children.toArray(children);
  const tiers = cols ?? fitPresets[kind];
  const sizes = tiers.map((c) => rowSizes(items.length, c));
  return (
    <div className="fit-c">
      <div className={`fit ${className}`}>
        {items.map((child, i) => {
          const style = Object.fromEntries(sizes.map((s, t) => [`--k${t}`, s[i]])) as CSSProperties;
          return (
            <div key={isValidElement(child) && child.key != null ? child.key : i} className="fit-i" style={style}>
              {child}
            </div>
          );
        })}
      </div>
    </div>
  );
}

/** Sticky jump links for a long page; the section in view is highlighted. */
export function JumpNav({ items }: { items: readonly (readonly [id: string, label: string])[] }) {
  const [active, setActive] = useState(items[0]?.[0] ?? '');
  const lock = useRef(0);
  useEffect(() => {
    // On scroll: the last section whose top has passed the sticky bars.
    // Read fresh each time, so sections that render late still count.
    let frame = 0;
    const pick = () => {
      frame = 0;
      if (Date.now() < lock.current) return;
      const line = window.innerHeight * 0.3;
      let current = items[0]?.[0] ?? '';
      let currentTop = -Infinity;
      for (const [id] of items) {
        const el = document.getElementById(id);
        const top = el?.getBoundingClientRect().top;
        // Sections side by side share a top: keep the first of them.
        if (top != null && top <= line && top > currentTop + 1) {
          current = id;
          currentTop = top;
        }
      }
      if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2) current = items[items.length - 1]?.[0] ?? current;
      setActive(current);
    };
    const onScroll = () => (frame ||= requestAnimationFrame(pick));
    pick();
    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll);
    return () => {
      window.removeEventListener('scroll', onScroll);
      window.removeEventListener('resize', onScroll);
      if (frame) cancelAnimationFrame(frame);
    };
  }, [items]);
  return (
    <nav className="jump no-print" aria-label="On this page">
      {items.map(([id, label]) => (
        <a
          key={id}
          href={`#${id}`}
          aria-current={active === id ? 'true' : undefined}
          onClick={(e) => {
            e.preventDefault();
            setActive(id);
            lock.current = Date.now() + 1000;
            document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
            history.replaceState(null, '', `#${id}`);
          }}
        >
          {label}
        </a>
      ))}
    </nav>
  );
}

/** A titled group of cards that JumpNav can jump to. */
export function Anchor({ id, title, hint, children }: { id: string; title: string; hint?: ReactNode; children: ReactNode }) {
  return (
    <section id={id} className="anchor stack">
      <div className="anchor-head">
        <h2>{title}</h2>
        {hint && <span className="small muted">{hint}</span>}
      </div>
      {children}
    </section>
  );
}
