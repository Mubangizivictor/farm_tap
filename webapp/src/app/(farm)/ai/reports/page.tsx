'use client';

// Smart Farm Reports (decision 0025): ask for a report in your own words;
// the table is made from the records and downloads as a spreadsheet (CSV)
// or prints / saves as PDF from the browser.

import { useMemo, useState } from 'react';
import { Icon } from '@/components/Icon';
import { AiTable, MethodBadge, ModuleHead } from '@/components/ai';
import { AiGate, useAiPage } from '@/components/aiPage';
import { Empty, ExportButtons } from '@/components/ui';
import { fmtDay } from '@/shared/aiCore';
import { seesMoney } from '@/shared/aiAccess';
import { periodOf } from '@/shared/aiAssistant';
import { buildReport, parseReportRequest, reportKinds, type Report, type ReportKind } from '@/shared/aiReports';
import { downloadCsv } from '@/lib/csv';
import { logAi } from '@/lib/ai';

const periods = [
  ['this week', 'Last 7 days'],
  ['this month', 'This month'],
  ['last month', 'Last month'],
  ['last 90 days', 'Last 90 days'],
] as const;

export default function Reports() {
  const page = useAiPage('reports');
  const { farm, ai } = page;
  const [text, setText] = useState('');
  const [report, setReport] = useState<Report | null>(null);
  const [miss, setMiss] = useState(false);
  const [period, setPeriod] = useState<string>('this month');
  const day = ai.data.now.slice(0, 10);
  const kinds = useMemo(() => reportKinds.filter((k) => !k.money || seesMoney(farm.role)), [farm.role]);

  const make = (kind: ReportKind, p = periodOf(period, day, 'month')) => {
    const t0 = performance.now();
    const r = buildReport(kind, p, ai.data);
    logAi(farm.id, 'reports', true, performance.now() - t0, 'calculated');
    setReport(r);
    setMiss(false);
  };
  const fromText = () => {
    const req = parseReportRequest(text, day, farm.role);
    if (!req) {
      setMiss(true);
      setReport(null);
      logAi(farm.id, 'reports', false, 0, 'calculated');
      return;
    }
    make(req.kind, req.period);
  };

  return (
    <>
      <ModuleHead module="reports" title="Smart Farm Reports" subtitle="Ask for a report in your own words, then print it or download it for Excel" />
      <AiGate page={page}>
        <section className="card stack no-print">
          <form
            className="ai-ask"
            onSubmit={(e) => {
              e.preventDefault();
              fromText();
            }}
          >
            <input className="input" value={text} onChange={(e) => setText(e.target.value)} placeholder="For example: milk report for last month" aria-label="Which report" maxLength={200} />
            <button className="btn" type="submit" disabled={!text.trim()}>
              <Icon name="chart" /> Make report
            </button>
          </form>
          {miss && <div className="banner warn small">I could not tell which report you want. Pick one below.</div>}
          <div className="row wrap">
            <span className="small muted">Period:</span>
            <div className="chips">
              {periods.map(([k, label]) => (
                <button key={k} type="button" className={`chip ${period === k ? 'brand' : ''}`} aria-pressed={period === k} onClick={() => setPeriod(k)}>
                  {label}
                </button>
              ))}
            </div>
          </div>
          <div className="chips">
            {kinds.map((k) => (
              <button key={k.key} type="button" className="chip" onClick={() => make(k.key)}>
                {k.label}
              </button>
            ))}
          </div>
        </section>
        {report ? (
          <section className="card stack">
            <div className="card-head">
              <div className="stack" style={{ gap: 'var(--s-xxs)' }}>
                <h2>{report.title}</h2>
                <span className="small muted">
                  {farm.name} · {fmtDay(report.period.from)} to {fmtDay(report.period.to)}
                </span>
              </div>
              <div className="row wrap no-print">
                <MethodBadge method="calculated" />
                <ExportButtons onCsv={() => downloadCsv(`${report.kind}-${report.period.from}-${report.period.to}`, report.columns, report.rows)} />
              </div>
            </div>
            <ul>
              {report.summary.map((s) => (
                <li key={s}>{s}</li>
              ))}
            </ul>
            {report.rows.length ? <AiTable label={report.title} columns={report.columns} rows={report.rows} /> : <Empty icon="chart">No records in this period.</Empty>}
            <p className="small muted no-print">To save as PDF, press Print and choose “Save as PDF”.</p>
          </section>
        ) : (
          !miss && <Empty icon="chart">Pick a report or type what you need.</Empty>
        )}
      </AiGate>
    </>
  );
}
