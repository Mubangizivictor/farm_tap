'use client';

// Financial Intelligence (decision 0025): owners and managers only. Every
// figure is a sum of recorded expenses, income and milk sales.

import { useMemo } from 'react';
import { Fit } from '@/components/fit';
import { AiTable, MethodBadge, ModuleHead } from '@/components/ai';
import { AiGate, ModuleFindings, useAiPage } from '@/components/aiPage';
import { CardHead, Empty, Stat } from '@/components/ui';
import { fmtL, fmtMonth, fmtUgx } from '@/shared/aiCore';
import { cashForecast, catLabel, monthsBack, unusualExpenses } from '@/shared/aiMoney';

export default function FinanceIntelligence() {
  const page = useAiPage('finance', ['herd', 'money', 'states']);
  const d = page.ai.data;
  const months = useMemo(() => monthsBack(d, 6), [d]);
  const cash = useMemo(() => cashForecast(d), [d]);
  const odd = useMemo(() => unusualExpenses(d), [d]);
  const [cur, prev] = months;
  const any = months.some((m) => m.spent || m.income);
  return (
    <>
      <ModuleHead module="finance" title="Financial Intelligence" subtitle="Where the money goes, what a litre costs, and what next month may look like" />
      <AiGate page={page}>
        <Fit kind="stats">
          <Stat icon="money" label={`${fmtMonth(cur.month)} so far`} value={fmtUgx(cur.net)} hint={`In ${fmtUgx(cur.income)} · out ${fmtUgx(cur.spent)}`} tone={cur.net < 0 ? 'warn' : undefined} />
          <Stat icon="money" label={fmtMonth(prev.month)} value={fmtUgx(prev.net)} hint={`In ${fmtUgx(prev.income)} · out ${fmtUgx(prev.spent)}`} tone={prev.net < 0 ? 'bad' : undefined} />
          <Stat icon="drop" label="Cost a litre (last month)" value={prev.costPerLitre != null ? fmtUgx(prev.costPerLitre) : '—'} hint={prev.litres ? `${fmtL(prev.litres)} produced` : undefined} />
          <Stat
            icon="trend"
            label={`Estimate for ${fmtMonth(cash.month)}`}
            value={cash.ok ? fmtUgx(cash.net) : '—'}
            hint={cash.ok ? `${cash.method}` : cash.reason}
            tone={cash.ok && cash.net < 0 ? 'warn' : undefined}
          />
        </Fit>
        <ModuleFindings page={page} module="finance" empty="No unusual spending or losses found." />
        <section className="card stack">
          <CardHead title="Last 6 months">
            <MethodBadge method="calculated" />
          </CardHead>
          {any ? (
            <AiTable
              label="Months"
              columns={['Month', 'Milk sales', 'Other income', 'Spent', 'Net', 'Cost a litre', 'Biggest cost']}
              right={[1, 2, 3, 4, 5]}
              rows={months.map((m) => [
                fmtMonth(m.month),
                fmtUgx(m.milkSales),
                fmtUgx(m.otherIncome),
                fmtUgx(m.spent),
                fmtUgx(m.net),
                m.costPerLitre != null ? fmtUgx(m.costPerLitre) : '—',
                m.byCategory[0] ? `${catLabel(m.byCategory[0].category)} (${Math.round((m.byCategory[0].amount / Math.max(1, m.spent)) * 100)}%)` : '—',
              ])}
            />
          ) : (
            <Empty icon="money">No money records yet. Record expenses and milk sales in Money.</Empty>
          )}
        </section>
        <Fit kind="cards" cols={[1, 2, 2, 2]}>
          <section className="card stack">
            <CardHead title={`Spending in ${fmtMonth(cur.month)}`}>
              <MethodBadge method="calculated" />
            </CardHead>
            {cur.byCategory.length ? (
              <AiTable label="Spending by category" columns={['Category', 'UGX', 'Share']} right={[1, 2]} rows={cur.byCategory.map((c) => [catLabel(c.category), fmtUgx(c.amount), `${Math.round((c.amount / Math.max(1, cur.spent)) * 100)}%`])} />
            ) : (
              <p className="small muted">No expenses yet this month.</p>
            )}
          </section>
          <section className="card stack">
            <CardHead title="Unusually large expenses">
              <MethodBadge method="statistical" />
            </CardHead>
            {odd.length ? (
              <AiTable label="Unusual expenses" columns={['Day', 'Category', 'Amount', 'Usual']} right={[2, 3]} rows={odd.map((u) => [u.at, catLabel(u.category), fmtUgx(u.amount), fmtUgx(u.usual)])} />
            ) : (
              <p className="small muted">None in the last 2 months. An expense is unusual when it is at least 3 times the usual size for its category (5 earlier ones needed).</p>
            )}
          </section>
        </Fit>
      </AiGate>
    </>
  );
}
