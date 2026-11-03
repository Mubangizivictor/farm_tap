import type { Farm, PlanState } from './domain.ts';
import { date } from './format.ts';

export const sectorName: Record<string, string> = {
  dairy: 'Dairy',
  poultry: 'Poultry',
  piggery: 'Piggery',
  goats: 'Goats',
  crops: 'Crops',
  fish: 'Fish',
};

export function farmKind(f: Farm): string {
  if (f.sector !== 'dairy') return `${sectorName[f.sector] ?? f.sector} farm`;
  if (f.type === 'centre') return 'Milk collection centre';
  if (f.type === 'both') return 'Dairy farm and collection centre';
  return 'Dairy farm';
}

export function roleName(f: Farm): string {
  if (f.roleTitle.trim()) return f.roleTitle.trim();
  return f.role.charAt(0).toUpperCase() + f.role.slice(1);
}

export function planText(p: PlanState): { text: string; tone: 'ok' | 'warn' | 'bad' | 'brand' } {
  switch (p.kind) {
    case 'trial':
      return p.daysLeft <= 0
        ? { text: 'Free trial ends today', tone: 'warn' }
        : { text: `Free trial: ${p.daysLeft} day${p.daysLeft === 1 ? '' : 's'} left`, tone: p.daysLeft <= 2 ? 'warn' : 'brand' };
    case 'paid':
      return { text: `Paid until ${date(p.until)}`, tone: 'ok' };
    case 'grace':
      return { text: `Payment due: ${p.daysLeft} day${p.daysLeft === 1 ? '' : 's'} left`, tone: 'warn' };
    case 'readOnly':
      return { text: 'Read only: pay to keep recording', tone: 'bad' };
  }
}
