'use client';

// Picture pickers (decision 0024): profile photos and the control panel's
// logo, stamp and signature. The picture is shrunk in the browser first.

import { useRef, useState } from 'react';
import { Icon } from '@/components/Icon';
import { shrinkImage, type Shrunk } from '@/lib/images';
import { Avatar } from '@/components/Avatar';

/** A round photo with Change and Remove. `onPick` gets a small square JPEG. */
export function PhotoPicker({
  photo,
  name,
  onPick,
  onRemove,
  disabled,
  size = 256,
}: {
  photo: string | null;
  name: string;
  onPick: (img: Shrunk) => Promise<void>;
  onRemove?: () => Promise<void>;
  disabled?: boolean;
  size?: number;
}) {
  const input = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const run = async (fn: () => Promise<void>) => {
    setBusy(true);
    setError('');
    try {
      await fn();
    } catch (e) {
      setError((e as Error).message || 'We could not save the picture. Try again.');
    } finally {
      setBusy(false);
    }
  };
  return (
    <div className="photo-picker">
      <Avatar size="xl" photo={photo} name={name} />
      <div className="stack">
        <div className="row wrap">
          <button type="button" className="btn outline sm" disabled={disabled || busy} onClick={() => input.current?.click()}>
            {busy ? <span className="spinner sm" aria-hidden /> : <Icon name="edit" />} {photo ? 'Change photo' : 'Add photo'}
          </button>
          {photo && onRemove && (
            <button type="button" className="btn ghost sm" disabled={disabled || busy} onClick={() => void run(onRemove)}>
              Remove
            </button>
          )}
        </div>
        <small className="muted">JPG or PNG. We shrink it before saving.</small>
        {error && <small className="error-text">{error}</small>}
      </div>
      <input
        ref={input}
        type="file"
        accept="image/*"
        hidden
        onChange={(e) => {
          const file = e.target.files?.[0];
          e.target.value = '';
          if (file) void run(async () => onPick(await shrinkImage(file, { max: size, square: true, quality: 0.82 })));
        }}
      />
    </div>
  );
}

/** A box for a logo, stamp or signature: shows the picture and takes a new one (PNG keeps clear backgrounds). */
export function AssetPicker({
  label,
  hint,
  value,
  onPick,
  onRemove,
  max = 800,
  disabled,
}: {
  label: string;
  hint: string;
  value: string | null;
  onPick: (img: Shrunk) => Promise<void>;
  onRemove?: () => Promise<void>;
  max?: number;
  disabled?: boolean;
}) {
  const input = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const run = async (fn: () => Promise<void>) => {
    setBusy(true);
    setError('');
    try {
      await fn();
    } catch (e) {
      setError((e as Error).message || 'We could not save the picture. Try again.');
    } finally {
      setBusy(false);
    }
  };
  return (
    <div className="stack">
      <strong>{label}</strong>
      <div className="asset-box">{value ? <img src={value} alt={label} /> : <span className="muted small">No picture yet</span>}</div>
      <small className="muted">{hint}</small>
      <div className="row wrap">
        <button type="button" className="btn outline sm" disabled={disabled || busy} onClick={() => input.current?.click()}>
          {busy ? <span className="spinner sm" aria-hidden /> : <Icon name="edit" />} {value ? 'Replace' : 'Upload'}
        </button>
        {value && onRemove && (
          <button type="button" className="btn ghost sm" disabled={disabled || busy} onClick={() => void run(onRemove)}>
            Remove
          </button>
        )}
      </div>
      {error && <small className="error-text">{error}</small>}
      <input
        ref={input}
        type="file"
        accept="image/png,image/jpeg,image/webp"
        hidden
        onChange={(e) => {
          const file = e.target.files?.[0];
          e.target.value = '';
          if (file) void run(async () => onPick(await shrinkImage(file, { max, png: true })));
        }}
      />
    </div>
  );
}
