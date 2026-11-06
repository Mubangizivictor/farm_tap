# shared/

TypeScript used by both the web app (`webapp/`) and the server code
(`functions/`). Edit the files here, then run:

    node shared/sync.mjs

It copies them into `webapp/src/shared/` and `functions/src/shared/` (both
committed, so each package builds on its own). `node shared/sync.mjs --check`
fails when a copy is out of date; the web and functions tests run it.

- `legal.ts`: the default Privacy Policy and Terms of Use (decision 0024), the
  operator details and a tiny Markdown reader for them.
- `billing.ts`: receipt and invoice numbering and the PDF layout (pdf-lib).
- `alerts.ts`: which reminders are due today (duties, vaccinations, calving,
  trial ending), the same rules as the phone's `alert_rules.dart`.
- `ai*.ts`: the AI engine (decision 0025). `aiCore` (dates, statistics,
  findings), `aiData` (record shapes, breeding state), `aiMilk`, `aiHerd`,
  `aiStock`, `aiMoney` (the analyses), `aiRisk` (all findings, ranked),
  `aiAccess` (roles and platform switches), `aiAssistant`, `aiVet`,
  `aiReports`, `aiPrivacy` (what may go to a self-hosted model). Tests:
  `webapp/src/lib/ai.test.ts`. These files import each other with `.ts`
  extensions; functions compile them with `rewriteRelativeImportExtensions`.
