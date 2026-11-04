// Numbers the way people in Uganda read them: "UGX 70,000", "12.5 L".

const whole = new Intl.NumberFormat('en-UG', { maximumFractionDigits: 0 });
const one = new Intl.NumberFormat('en-UG', { maximumFractionDigits: 1, minimumFractionDigits: 0 });

export const ugx = (n: number) => `UGX ${whole.format(Math.round(n))}`;
export const litres = (n: number) => `${one.format(n)} L`;
export const count = (n: number) => whole.format(n);
export const num1 = (n: number) => one.format(n);

const dateFmt = new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
const shortFmt = new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short' });
const timeFmt = new Intl.DateTimeFormat('en-GB', { hour: '2-digit', minute: '2-digit' });
const dayFmt = new Intl.DateTimeFormat('en-GB', { weekday: 'short' });
const longFmt = new Intl.DateTimeFormat('en-GB', { weekday: 'long', day: 'numeric', month: 'long' });

export const date = (d: Date | null) => (d ? dateFmt.format(d) : '');
export const shortDate = (d: Date | null) => (d ? shortFmt.format(d) : '');
export const time = (d: Date | null) => (d ? timeFmt.format(d) : '');
export const weekday = (d: Date) => dayFmt.format(d);
export const longDate = (d: Date) => longFmt.format(d);

/** "Good morning" by the browser's clock. */
export function greeting(now: Date): string {
  const h = now.getHours();
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

/** First name for the greeting ("Victor" from "Mubangizi Victor" stays as typed first word). */
export function firstName(name: string | null | undefined): string {
  return (name ?? '').trim().split(/\s+/)[0] ?? '';
}

export function initials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  return ((parts[0]?.[0] ?? '') + (parts[1]?.[0] ?? '')).toUpperCase() || '?';
}

/** "mastitis" -> "Mastitis", "addedWater" -> "Added water". */
export function words(key: string | null | undefined): string {
  if (!key) return '';
  const s = key.replace(/([a-z])([A-Z])/g, '$1 $2').replace(/[_-]+/g, ' ').toLowerCase();
  return s.charAt(0).toUpperCase() + s.slice(1);
}

/** "1 entry", "3 entries": a count with the right word after it. */
export const plural = (n: number, one: string, many: string) => `${whole.format(n)} ${n === 1 ? one : many}`;
