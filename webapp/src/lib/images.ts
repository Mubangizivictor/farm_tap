'use client';

// Picture uploads (decision 0024): profile photos, logo, stamp, signature.
// Every picture is shrunk in the browser first. A small copy is always saved
// in the database (works today). When file storage is switched on (Blaze),
// the full copy also goes there and its link is saved alongside; if storage
// is off, that step is skipped quietly and the small copy is used.

import { getApp } from 'firebase/app';
import { getDownloadURL, getStorage, ref, uploadString } from 'firebase/storage';
import { firebase } from './firebase.ts';

export const MAX_UPLOAD_BYTES = 8 * 1024 * 1024;

export interface Shrunk {
  dataUrl: string;
  width: number;
  height: number;
}

function readFile(file: File): Promise<string> {
  return new Promise((ok, bad) => {
    const r = new FileReader();
    r.onload = () => ok(String(r.result));
    r.onerror = () => bad(new Error('We could not read that picture.'));
    r.readAsDataURL(file);
  });
}

function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((ok, bad) => {
    const img = new Image();
    img.onload = () => ok(img);
    img.onerror = () => bad(new Error('That file is not a picture we can open. Use a JPG or PNG.'));
    img.src = src;
  });
}

/**
 * Shrinks a picture to fit `max` pixels. `png` keeps see-through parts (a
 * signature or stamp on a clear background); photos use JPEG.
 * `square` crops the middle (profile photos).
 */
export async function shrinkImage(file: File, opts: { max: number; png?: boolean; square?: boolean; quality?: number }): Promise<Shrunk> {
  if (!file.type.startsWith('image/')) throw new Error('Choose a picture (JPG or PNG).');
  if (file.size > MAX_UPLOAD_BYTES) throw new Error('That picture is too big. Choose one under 8 MB.');
  const img = await loadImage(await readFile(file));
  let sx = 0;
  let sy = 0;
  let sw = img.naturalWidth;
  let sh = img.naturalHeight;
  if (opts.square) {
    const side = Math.min(sw, sh);
    sx = (sw - side) / 2;
    sy = (sh - side) / 2;
    sw = sh = side;
  }
  const scale = Math.min(1, opts.max / Math.max(sw, sh));
  const width = Math.max(1, Math.round(sw * scale));
  const height = Math.max(1, Math.round(sh * scale));
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('This browser cannot prepare pictures.');
  ctx.imageSmoothingQuality = 'high';
  ctx.drawImage(img, sx, sy, sw, sh, 0, 0, width, height);
  const dataUrl = opts.png ? canvas.toDataURL('image/png') : canvas.toDataURL('image/jpeg', opts.quality ?? 0.85);
  return { dataUrl, width, height };
}

/** Puts the picture in file storage. null when storage is not switched on yet. */
export async function storeImage(path: string, dataUrl: string): Promise<string | null> {
  try {
    firebase();
    const r = ref(getStorage(getApp()), path);
    await uploadString(r, dataUrl, 'data_url', { cacheControl: 'public,max-age=3600' });
    return await getDownloadURL(r);
  } catch {
    return null;
  }
}

/** Rough size of a data URL in bytes (database documents must stay small). */
export const dataUrlBytes = (u: string) => Math.ceil(((u.length - u.indexOf(',') - 1) * 3) / 4);

/** A person's picture from their record: the stored link, else the small copy kept in the record. */
export function personPhotoSrc(body: { photo?: string | null; photoUrl?: string | null }): string | null {
  if (body.photoUrl) return body.photoUrl;
  const p = body.photo;
  if (!p) return null;
  if (p.startsWith('data:') || p.startsWith('http')) return p;
  return /^[A-Za-z0-9+/=]+$/.test(p) ? `data:image/jpeg;base64,${p}` : null;
}

/** The phone's record shape: `photo` holds the base64 copy without the "data:" part. */
export const base64Of = (dataUrl: string) => dataUrl.slice(dataUrl.indexOf(',') + 1);
