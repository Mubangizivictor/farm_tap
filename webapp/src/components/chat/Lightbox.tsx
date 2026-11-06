'use client';

// Full-screen look at a photo (decision 0027): zoom, step through the photos, and the AI's numbered
// points listed beside it. Esc or the close button leaves.

import { useEffect, useState } from 'react';
import { Icon } from '@/components/Icon';
import { PinList } from '@/components/chat/Messages';
import type { ChatPin } from '@/shared/aiChat';

export interface LightPhoto {
  src: string;
  name: string;
}

export function Lightbox({ photos, start, pins, onClose }: { photos: LightPhoto[]; start: number; pins: ChatPin[]; onClose: () => void }) {
  const [i, setI] = useState(Math.min(start, photos.length - 1));
  const [zoom, setZoom] = useState(1);
  const to = (n: number) => {
    setI((n + photos.length) % photos.length);
    setZoom(1);
  };
  useEffect(() => {
    const key = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
      else if (e.key === 'ArrowRight') to(i + 1);
      else if (e.key === 'ArrowLeft') to(i - 1);
    };
    window.addEventListener('keydown', key);
    return () => window.removeEventListener('keydown', key);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [i, photos.length]);
  const cur = photos[i];
  if (!cur) return null;
  return (
    <div className="ct-lb" role="dialog" aria-modal="true" aria-label="Photo">
      <div className="ltop">
        <button className="ct-ib" aria-label="Close" onClick={onClose}><Icon name="close" /></button>
        <span className="grow small">{cur.name} · {i + 1} of {photos.length}</span>
        <a className="ct-ib" aria-label="Save the photo" href={cur.src} download={cur.name}><Icon name="download" /></a>
      </div>
      <div className="stagepic">
        <div className="imgwrap" style={{ transform: `scale(${zoom})` }}>
          <img src={cur.src} alt={cur.name} />
          {i === 0 && pins.map((p) => <span key={p.n} className={`ct-pin ${p.tone}`} style={{ left: `${p.x}%`, top: `${p.y}%` }}>{p.n}</span>)}
        </div>
        {photos.length > 1 && (
          <>
            <button className="nav prev" aria-label="Previous photo" onClick={() => to(i - 1)}><Icon name="chevron" /></button>
            <button className="nav next" aria-label="Next photo" onClick={() => to(i + 1)}><Icon name="chevron" /></button>
          </>
        )}
        <div className="zoom">
          <button className="ct-ib" aria-label="Zoom out" disabled={zoom <= 1} onClick={() => setZoom(Math.max(1, zoom - 0.5))}><Icon name="zoomOut" /></button>
          <span className="small">{Math.round(zoom * 100)}%</span>
          <button className="ct-ib" aria-label="Zoom in" disabled={zoom >= 3} onClick={() => setZoom(Math.min(3, zoom + 0.5))}><Icon name="zoomIn" /></button>
        </div>
      </div>
      {photos.length > 1 && (
        <div className="strip">
          {photos.map((p, n) => (
            <button key={n} className={`th${n === i ? ' cur' : ''}`} aria-label={`Photo ${n + 1}`} onClick={() => to(n)}><img src={p.src} alt="" /></button>
          ))}
        </div>
      )}
      {pins.length > 0 && i === 0 && (
        <aside className="panel">
          <strong>What I looked at</strong>
          <PinList pins={pins} />
          <p className="small">This is a guide, not a diagnosis. Show your vet.</p>
        </aside>
      )}
    </div>
  );
}
