// Even rows for card grids (admin retouch). Given N items and at most C
// columns, split them into the fewest rows, as evenly as possible, so the
// last row never leaves an empty column: 1 item is full width, 4 items in
// 3 columns become 2 + 2, 5 become 3 + 2.

/** Items per row for each item, in order. */
export function rowSizes(n: number, maxCols: number): number[] {
  if (n <= 0) return [];
  const c = Math.max(1, Math.min(Math.floor(maxCols), n));
  const rows = Math.ceil(n / c);
  const base = Math.floor(n / rows);
  const extra = n % rows;
  const out: number[] = [];
  for (let r = 0; r < rows; r++) {
    const size = base + (r < extra ? 1 : 0);
    for (let i = 0; i < size; i++) out.push(size);
  }
  return out;
}

/** Most columns at each container width tier: under 560, 560-899, 900-1199, 1200+. */
export const fitPresets = {
  stats: [2, 3, 4, 6],
  cards: [1, 2, 3, 4],
  fields: [1, 2, 3, 4],
} as const;
export type FitKind = keyof typeof fitPresets;
