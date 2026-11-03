/** Lowest free 4-digit card number, so no two people ever share a card. */
export function nextFreeCard(taken: Set<string>): string {
  for (let n = 1; n < 10000; n++) {
    const c = String(n).padStart(4, '0');
    if (!taken.has(c)) return c;
  }
  return '';
}
