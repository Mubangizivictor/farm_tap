// Staff PIN hashes in the same form the phone makes and checks
// (lib/core/people/data/pin_security.dart): PBKDF2 with HMAC-SHA256,
// 16-byte random salt, 32-byte key, stored as
// `pbkdf2-sha256$<iterations>$<salt base64>$<hash base64>`.
// The PIN itself never leaves the browser.

export const PIN_ITERATIONS = 20000;

const b64 = (bytes: Uint8Array) => btoa(String.fromCharCode(...bytes));

export async function hashPin(
  pin: string,
  salt: Uint8Array = crypto.getRandomValues(new Uint8Array(16)),
  iterations = PIN_ITERATIONS,
): Promise<string> {
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(pin), 'PBKDF2', false, ['deriveBits']);
  const bits = await crypto.subtle.deriveBits({ name: 'PBKDF2', hash: 'SHA-256', salt: salt as BufferSource, iterations }, key, 256);
  return `pbkdf2-sha256$${iterations}$${b64(salt)}$${b64(new Uint8Array(bits))}`;
}

/** A starting PIN is 4 numbers, not all the same and not a run like 1234. */
export function pinProblem(pin: string): string | null {
  if (!/^\d{4}$/.test(pin)) return 'A PIN is 4 numbers.';
  if (/^(\d)\1{3}$/.test(pin)) return 'Use different numbers, not the same one four times.';
  if ('0123456789'.includes(pin) || '9876543210'.includes(pin)) return 'Avoid easy PINs like 1234.';
  return null;
}
