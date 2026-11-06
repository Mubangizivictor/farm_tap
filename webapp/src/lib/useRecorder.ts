'use client';

// Voice notes for the AI chat (decision 0027): records from the microphone and gives back a small
// mono 16 kHz WAV (a format Gemini reads), as base64. Nothing is kept or sent until the farmer sends it.

import { useCallback, useEffect, useRef, useState } from 'react';

export const VOICE_MAX_SECONDS = 90;
const RATE = 16_000;

export interface VoiceNote {
  base64: string;
  seconds: number;
}

/** 16-bit mono WAV bytes from float samples. */
export function wavOf(samples: Float32Array, rate = RATE): Uint8Array {
  const out = new Uint8Array(44 + samples.length * 2);
  const v = new DataView(out.buffer);
  const text = (at: number, s: string) => [...s].forEach((c, i) => v.setUint8(at + i, c.charCodeAt(0)));
  text(0, 'RIFF');
  v.setUint32(4, 36 + samples.length * 2, true);
  text(8, 'WAVE');
  text(12, 'fmt ');
  v.setUint32(16, 16, true);
  v.setUint16(20, 1, true);
  v.setUint16(22, 1, true);
  v.setUint32(24, rate, true);
  v.setUint32(28, rate * 2, true);
  v.setUint16(32, 2, true);
  v.setUint16(34, 16, true);
  text(36, 'data');
  v.setUint32(40, samples.length * 2, true);
  samples.forEach((s, i) => v.setInt16(44 + i * 2, Math.round(Math.max(-1, Math.min(1, s)) * 32767), true));
  return out;
}

export function base64Of(bytes: Uint8Array): string {
  let s = '';
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(s);
}

async function toWav(blob: Blob): Promise<VoiceNote> {
  const ctx = new OfflineAudioContext(1, 1, RATE);
  const decoded = await ctx.decodeAudioData(await blob.arrayBuffer());
  const frames = Math.max(1, Math.ceil(decoded.duration * RATE));
  const off = new OfflineAudioContext(1, frames, RATE);
  const src = off.createBufferSource();
  src.buffer = decoded;
  src.connect(off.destination);
  src.start();
  const done = await off.startRendering();
  return { base64: base64Of(wavOf(done.getChannelData(0))), seconds: Math.round(decoded.duration) };
}

export function useRecorder() {
  const [recording, setRecording] = useState(false);
  const [seconds, setSeconds] = useState(0);
  const [levels, setLevels] = useState<number[]>([]);
  const [error, setError] = useState('');
  const rec = useRef<MediaRecorder | null>(null);
  const chunks = useRef<Blob[]>([]);
  const stream = useRef<MediaStream | null>(null);
  const timer = useRef<ReturnType<typeof setInterval> | null>(null);
  const meter = useRef<{ ctx: AudioContext; raf: number } | null>(null);
  const finish = useRef<((n: VoiceNote | null) => void) | null>(null);
  const supported = typeof window !== 'undefined' && !!navigator.mediaDevices?.getUserMedia && typeof MediaRecorder !== 'undefined';

  const cleanup = useCallback(() => {
    if (timer.current) clearInterval(timer.current);
    timer.current = null;
    if (meter.current) {
      cancelAnimationFrame(meter.current.raf);
      void meter.current.ctx.close();
      meter.current = null;
    }
    stream.current?.getTracks().forEach((t) => t.stop());
    stream.current = null;
    setRecording(false);
  }, []);

  const start = useCallback(async () => {
    setError('');
    if (!supported) {
      setError('This browser cannot record voice.');
      return;
    }
    try {
      const s = await navigator.mediaDevices.getUserMedia({ audio: true });
      stream.current = s;
      chunks.current = [];
      const r = new MediaRecorder(s);
      r.ondataavailable = (e) => e.data.size && chunks.current.push(e.data);
      r.onstop = () => {
        const blob = new Blob(chunks.current, { type: r.mimeType || 'audio/webm' });
        const cb = finish.current;
        finish.current = null;
        cleanup();
        if (!cb) return;
        toWav(blob).then(cb, () => {
          setError('Could not read that recording. Try again.');
          cb(null);
        });
      };
      rec.current = r;
      r.start();
      setSeconds(0);
      setLevels([]);
      setRecording(true);
      timer.current = setInterval(() => {
        setSeconds((n) => {
          if (n + 1 >= VOICE_MAX_SECONDS && rec.current?.state === 'recording') rec.current.stop();
          return n + 1;
        });
      }, 1000);
      const ctx = new AudioContext();
      const an = ctx.createAnalyser();
      an.fftSize = 256;
      ctx.createMediaStreamSource(s).connect(an);
      const data = new Uint8Array(an.frequencyBinCount);
      let last = 0;
      const tick = (t: number) => {
        if (t - last > 90) {
          last = t;
          an.getByteTimeDomainData(data);
          let peak = 0;
          data.forEach((d) => (peak = Math.max(peak, Math.abs(d - 128))));
          setLevels((l) => [...l.slice(-39), Math.min(1, peak / 90)]);
        }
        if (meter.current) meter.current.raf = requestAnimationFrame(tick);
      };
      meter.current = { ctx, raf: requestAnimationFrame(tick) };
    } catch {
      cleanup();
      setError('FarmTap cannot use the microphone. Allow it in your browser settings.');
    }
  }, [cleanup, supported]);

  /** Stops and gives the note; null when it could not be read. */
  const stop = useCallback(
    () =>
      new Promise<VoiceNote | null>((ok) => {
        if (!rec.current || rec.current.state !== 'recording') return ok(null);
        finish.current = ok;
        rec.current.stop();
      }),
    [],
  );
  const cancel = useCallback(() => {
    finish.current = null;
    if (rec.current?.state === 'recording') rec.current.stop();
    cleanup();
  }, [cleanup]);

  useEffect(() => cancel, [cancel]);
  return { supported, recording, seconds, levels, error, start, stop, cancel };
}
