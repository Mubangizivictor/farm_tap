// GENERATED from shared/ by `node shared/sync.mjs`. Edit the file in shared/, not this copy.
// FarmTap legal documents (decision 0024): the operator, the default Privacy
// Policy and Terms of Use, and a small reader for their Markdown.
//
// These are production-ready defaults. Victor edits and publishes new
// versions in the control panel (Legal documents); the public pages
// /privacy/ and /terms/ show the latest published version, or these when
// nothing has been published yet. No imports, so the web app and the server
// code can both use this file.

export type LegalKind = 'privacy' | 'terms';
export const legalKinds: LegalKind[] = ['privacy', 'terms'];

export interface Operator {
  company: string;
  product: string;
  address: string;
  country: string;
  phone: string;
  email: string;
  website: string;
}

/** Who runs FarmTap. The panel's support settings override phone and email. */
export const OPERATOR: Operator = {
  company: 'Victorbee Technologies',
  product: 'FarmTap',
  address: 'Mbarara City, Western Uganda',
  country: 'Uganda',
  phone: '+256 793 128 137',
  email: 'farmtap.ug@gmail.com',
  website: 'https://farmtap.victorbee.com',
};

export interface Signatory {
  name: string;
  title: string;
}

export const DEFAULT_SIGNATORY: Signatory = { name: 'Victor Mubangizi', title: 'Chief Executive Officer, Victorbee Technologies' };

/** A published (or default) version of one document. */
export interface LegalDoc {
  kind: LegalKind;
  title: string;
  /** 1, 2, 3... Each publish is a new version; old ones are kept. */
  version: number;
  /** yyyy-mm-dd: the day this version applies from. */
  effectiveDate: string;
  /** Markdown: # / ## / ### headings, paragraphs, "- " bullets, **bold**. */
  body: string;
  signatory: Signatory;
  /** One line on what changed, shown in the version history. */
  summary: string;
}

export const DEFAULT_EFFECTIVE_DATE = '2026-11-04';

/** Fills {company}, {phone}... in a document body. */
export function fillOperator(text: string, op: Operator = OPERATOR): string {
  return text
    .replace(/\{company\}/g, op.company)
    .replace(/\{product\}/g, op.product)
    .replace(/\{address\}/g, op.address)
    .replace(/\{country\}/g, op.country)
    .replace(/\{phone\}/g, op.phone)
    .replace(/\{email\}/g, op.email)
    .replace(/\{website\}/g, op.website);
}

const PRIVACY = `This Privacy Policy explains what information {product} collects, why, how it is kept safe, who it is shared with and the choices you have. It applies to the {product} phone app, the {product} website at {website} and the {product} control panel. {product} is run by **{company}**, {address}, {country} ("we", "us").

We follow the **Data Protection and Privacy Act, 2019** of Uganda and the **Data Protection and Privacy Regulations, 2021**. For the farm records you keep in {product}, your farm or centre is the data controller and we process those records on your behalf. For your account and for running the service, we are the data controller.

## 1. Information we collect

### Information you give us
- **Your account:** your name, email address, and your Google or Apple account name when you sign in with them. We never see your Google or Apple password.
- **Your farm or centre:** its name, district, village, type, number of animals, WhatsApp and SMS numbers, and your role on it.
- **Farm records:** animals (tags, names, breed, dates, photos), milk, health and treatments, vaccinations, breeding and calving, feeds and stock, money in and out, reports, tasks and duty rosters.
- **People you add:** workers and managers (name, phone number, role, department, photo, ID card number, pay terms, attendance; a National ID number or next of kin only if you choose to add them), milk suppliers and farmers (name, phone, village, deliveries and payments), and contacts such as vets and suppliers.
- **Staff sign-in:** a worker's phone number and a 4-digit PIN. The PIN is stored only as a one-way code (a hash), never as the PIN itself.
- **Payments for {product}:** the plan, the amount, the Mobile Money number used to pay, and the transaction reference. Card numbers go straight to the card payment company; we never see or keep them.
- **Messages to us:** what you send to support on WhatsApp, by phone or by email.

### Information collected when you use {product}
- **Device and app information:** app version, phone model, operating system, a random ID for each installed app, and crash reports, so we can fix problems.
- **Usage information:** which screens are opened and which features are used, without the content of your records, so we can improve {product}.
- **Camera, NFC and location:** the camera is used only when you scan a QR code or take a photo; NFC only when you tap a card; your location only if you choose to fill in the farm's place from the phone. We do not track your location.
- **Notifications:** a notification token for your phone, so we can send you the reminders you switch on.

We do not collect information about your contacts list, your SMS inbox or your calls.

## 2. Why we use it (lawful basis)
- **To provide {product}** (keeping your records, syncing them between your phones and the website, sign-in, ID cards, reports): this is needed to perform our agreement with you.
- **To send reminders and messages you ask for** (duties, vaccinations, calving, trial and payment reminders, milk receipts and statements): with your consent, which you can switch off in Settings at any time.
- **To take payment for {product}** and issue receipts and invoices: to perform our agreement and to meet our tax and accounting duties.
- **To keep {product} secure** and prevent misuse, and to fix errors: our legitimate interest in running a safe service.
- **To answer support requests:** to perform our agreement and our legitimate interest.
- **To meet the law:** where a law of Uganda requires us to keep or share information.

We do **not** sell your information, and we do not use your farm records for advertising.

## 3. Who we share it with
We share information only with companies that help us run {product}, under written terms that require them to protect it and use it only for us:
- **Google Cloud** (Google LLC): hosting, database, sign-in, file storage, crash reports, usage statistics and phone notifications.
- **Payment companies:** MTN Mobile Money Uganda, Airtel Money Uganda and Flutterwave (card payments), only to take a payment you start.
- **SMS company** (for example Africa's Talking), only if your farm switches on automatic SMS: the phone number and the text of each message.

We also share information:
- **Inside your farm:** people you add to your farm see the records their role allows. A milk supplier you invite sees only their own deliveries and payments.
- **When the law requires it:** to answer a lawful order of a court or authority in Uganda, or to protect the safety of a person.
- **If {company} is sold or merged:** the new owner must keep this policy or tell you before it changes.

## 4. Where your information is kept
Your information is stored on Google Cloud servers, which may be outside Uganda (for example in Europe). As the Act requires, we only use providers in countries or under contracts that give your information protection at least as strong as the law of Uganda. Your phone also keeps a copy of your farm's records so {product} works without the internet.

## 5. How long we keep it
- Farm records are kept while your account is open, so you can look back over past years.
- If a plan ends and is not renewed, the records stay readable (read-only) for at least **12 months**, then we may delete them after telling you.
- When you ask us to delete your account, it is closed straight away: nobody can sign in to it and your farm stops showing in {product}. Your information is then kept, locked, for **90 days** in case you change your mind or it was deleted by mistake; within those 90 days you can ask us to bring it back. After 90 days it is erased for good, except what the law requires us to keep: payment records, receipts and invoices are kept for **7 years** (tax law). Backups are overwritten within a further 35 days.
- Crash reports and usage statistics are kept for up to 14 months.

## 6. How we protect it
- Information travels encrypted (HTTPS/TLS) and is encrypted where it is stored.
- Security rules on our servers let each person see only the farms they belong to, and only what their role allows.
- PINs are stored as one-way codes, and payment and SMS keys are kept only on the server, never in the app.
- Only a small number of our staff can reach the control panel, each with their own sign-in, and every change they make is logged.

No system is perfectly secure. If a breach puts your information at risk, we will tell you and the Personal Data Protection Office as the law requires.

## 7. Your rights
Under the Data Protection and Privacy Act, 2019 you have the right to:
- **see** the information we hold about you and get a copy of it;
- **correct** information that is wrong or incomplete (most of it you can change yourself in the app);
- **object** to us using your information, or ask us to stop using it for a purpose;
- **withdraw consent** for reminders and messages at any time in Settings;
- **ask us to delete** your account and information (see section 8).

To use any of these rights, contact us (section 11). We answer within 30 days. You may also complain to the **Personal Data Protection Office**, National Information Technology Authority–Uganda (NITA-U), Kampala (www.pdpo.go.ug).

Farm owners: when a worker or a supplier asks you about the information your farm keeps about them, you can answer from {product}, and we will help you.

## 8. Deleting your account
You can ask us to delete your account at any time:
- in the app: **Settings → Delete my account**;
- on the web, without signing in: **{website}/delete-account/**;
- or by WhatsApp or phone on {phone}.

Before anything is deleted, {product} shows you what will be lost and asks you to confirm. Your account is then closed at once and erased for good after 90 days, as described in section 5. To bring it back within the 90 days, contact us on {phone}. Deleting a farm owner's account closes the farm for everyone on it, so the owner should download any reports they need first.

## 9. Children
{product} is for farms and businesses. It is not meant for anyone under 18, and we do not knowingly collect information about children as users. If a farm records a worker who is under 18, the farm is responsible for having the consent of the parent or guardian, as the law requires.

## 10. Changes to this policy
When we change this policy we publish the new version here with a new date and version number. If a change is important, we also tell you in the app or by email before it applies. Earlier versions are available on request.

## 11. Contact us
**{company}** ({product})
{address}, {country}
WhatsApp and phone: **{phone}**
Email: **{email}**
Website: {website}`;

const TERMS = `These Terms of Use are the agreement between you and **{company}**, {address}, {country} ("we", "us"), for using {product}: the phone app, the website at {website} and the services that come with them. By creating an account or using {product} you agree to these terms. If you use {product} for a farm, collection centre or business, you agree for it too and confirm you may do so.

## 1. What {product} is
{product} helps farms and milk collection centres keep their records: animals, milk, health, breeding, feeds, workers, suppliers, money and reports, on the phone (also without the internet) and on the web. {product} is a record-keeping tool. It does **not** give veterinary, medical, legal, tax or financial advice. Always ask a qualified vet about animal health, drug withdrawal times and vaccinations.

## 2. Your account
- You must be **18 or older** and give true information.
- Keep your sign-in, your PIN and your staff cards safe. You are responsible for what is done with your account, your cards and the phones you sign in on. Tell us at once if you think someone else is using them.
- One account runs one farm or centre unless your plan allows more.
- The owner of a farm decides who joins it and what each person can do, and can remove people at any time.

## 3. Free trial, plans and payment
- A new farm gets a **free trial** (the number of days shown when you sign up). No payment details are needed for the trial.
- After the trial, a **paid plan** is needed to keep adding records. The plans and prices are shown in the app and on our website, in Uganda shillings (UGX), and may include taxes as shown.
- You can pay with MTN Mobile Money, Airtel Money, card, or any other way shown in the app. A plan starts when the payment is confirmed and runs for the period paid.
- **When a plan or trial ends and is not paid, the farm becomes read-only:** you can still open and download your records, but you cannot add or change them until you pay. There is no automatic renewal: you choose when to pay again.
- We send an electronic receipt and invoice for each payment.
- We may change prices. A new price never applies to a period you have already paid for, and we announce changes at least 30 days before they apply.

## 4. Refunds
- If you were charged twice, charged the wrong amount, or paid but your plan did not start, tell us within **30 days** and we will correct it or refund the difference.
- If you are not happy, you may ask for a refund within **7 days** of your first payment for a plan; we refund it in full if you have not used the paid period much.
- Otherwise payments for a period that has started are not refundable, but you can choose not to renew.
- Refunds go back to the Mobile Money number or card that paid, usually within 14 days of approval. Mobile Money and card charges taken by the network may not be returned.

## 5. Your data
- **Your records belong to you** (your farm or centre). You give us permission to store, copy, process and show them only to run {product} for you, as described in our Privacy Policy.
- You can download your records (PDF and spreadsheet) while your account is open.
- You are responsible for having the right to record information about other people (workers, suppliers, farmers, contacts) and for telling them that you use {product}, as the Data Protection and Privacy Act, 2019 requires.
- We may use counts that cannot identify you or your farm (for example "how many farms use {product}") to improve the service.

## 6. Acceptable use
You must not:
- break the law, or use {product} to cheat suppliers, workers, buyers or anyone else;
- record false information to mislead others, for example about milk quantities, payments or drug withdrawal;
- try to get into farms, accounts or parts of {product} that are not yours, or test, scan or attack its security;
- copy, sell, rent or rebuild {product}, or use automated tools to collect information from it;
- send spam, or use {product}'s messages to harass anyone. Messages to farmers and workers must be about your farm's business.

## 7. Messages and reminders
{product} can prepare reminders, receipts and statements. When you send them from your phone (WhatsApp or SMS), your own network charges apply. Automatic SMS sent by {product} is an optional paid service. You must have the person's agreement to send them messages, and stop when they ask.

## 8. Availability and changes
We work to keep {product} available and your records safe, and the phone app keeps working without the internet. But {product} is provided "as is": we cannot promise it will always be free of errors or interruptions, for example during network or power problems or maintenance. We may improve, change or stop features; if we stop {product} altogether we will give you at least 60 days to download your records.

## 9. Limits on our responsibility
To the extent the law allows:
- we are not responsible for losses caused by wrong or missing records entered by users, by decisions taken from {product}'s numbers (for example milk payments or animal treatment), by loss of a phone, or by events outside our reasonable control;
- we are not responsible for indirect losses such as lost profit or lost business;
- our total responsibility for any claim is limited to the amount you paid us for {product} in the 12 months before the claim.
Nothing in these terms takes away rights you have under the consumer laws of Uganda that cannot be taken away.

## 10. Suspending and closing accounts
- You can stop using {product} and ask us to delete your account at any time (see the Privacy Policy, section 8).
- We may suspend or close an account that breaks these terms, puts others at risk, or is used for fraud, after warning you where we reasonably can. You can still ask for a copy of your records unless the law stops us.

## 11. Intellectual property
{product}, its name, logo, designs and software belong to {company}. We give you a personal, non-exclusive right to use {product} while your account is open and you keep these terms.

## 12. Changes to these terms
We may update these terms. We publish the new version here with a new date and version number and, for important changes, tell you in the app at least 14 days before they apply. If you keep using {product} after that, the new terms apply; if you do not agree, you may stop and ask us to delete your account.

## 13. Law and disputes
These terms are governed by the laws of the Republic of Uganda. If there is a problem, please contact us first and we will try to solve it within 30 days. If we cannot agree, the dispute goes to the courts of Uganda (the High Court sitting at Mbarara, unless the law says otherwise).

## 14. Contact us
**{company}** ({product})
{address}, {country}
WhatsApp and phone: **{phone}**
Email: **{email}**
Website: {website}`;

export const DEFAULT_LEGAL: Record<LegalKind, LegalDoc> = {
  privacy: {
    kind: 'privacy',
    title: 'Privacy Policy',
    version: 1,
    effectiveDate: DEFAULT_EFFECTIVE_DATE,
    body: PRIVACY,
    signatory: DEFAULT_SIGNATORY,
    summary: 'First version.',
  },
  terms: {
    kind: 'terms',
    title: 'Terms of Use',
    version: 1,
    effectiveDate: DEFAULT_EFFECTIVE_DATE,
    body: TERMS,
    signatory: DEFAULT_SIGNATORY,
    summary: 'First version.',
  },
};

const obj = (v: unknown): Record<string, unknown> => (v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : {});
const str = (v: unknown, d: string) => (typeof v === 'string' && v.trim() !== '' ? v : d);

/** Reads legalDocs/{kind} (or a version under it); falls back to the default. */
export function legalFromDoc(kind: LegalKind, data: unknown): LegalDoc {
  const d = obj(data);
  const D = DEFAULT_LEGAL[kind];
  const s = obj(d.signatory);
  const v = typeof d.version === 'number' && d.version >= 1 ? Math.round(d.version) : D.version;
  const date = str(d.effectiveDate, D.effectiveDate);
  return {
    kind,
    title: str(d.title, D.title),
    version: v,
    effectiveDate: /^\d{4}-\d{2}-\d{2}$/.test(date) ? date : D.effectiveDate,
    body: str(d.body, D.body),
    signatory: { name: str(s.name, D.signatory.name), title: str(s.title, D.signatory.title) },
    summary: str(d.summary, ''),
  };
}

/** "4 November 2026". */
export function longDate(iso: string): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso);
  if (!m) return iso;
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  return `${Number(m[3])} ${months[Number(m[2]) - 1] ?? ''} ${m[1]}`;
}

// ---------------------------------------------------------------- Markdown

export type Inline = { text: string; bold: boolean }[];
export type Heading = { type: 'h1' | 'h2' | 'h3'; text: string; id: string };
export type Block =
  | Heading
  | { type: 'p'; lines: Inline[] }
  | { type: 'ul'; items: Inline[] };

/** "**Hi** there" -> [{Hi, bold}, { there}]. */
export function inline(text: string): Inline {
  const out: Inline = [];
  const parts = text.split(/(\*\*[^*]+\*\*)/g);
  for (const p of parts) {
    if (!p) continue;
    if (p.startsWith('**') && p.endsWith('**') && p.length > 4) out.push({ text: p.slice(2, -2), bold: true });
    else out.push({ text: p, bold: false });
  }
  return out;
}

export const slug = (t: string) =>
  t
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60);

/**
 * The small Markdown the legal pages use: headings (#, ##, ###), "- "
 * bullets, paragraphs (lines kept as line breaks) and **bold**. Anything
 * else is plain text, so a typo can never break the page.
 */
export function parseMarkdown(md: string): Block[] {
  const blocks: Block[] = [];
  let para: Inline[] = [];
  let list: Inline[] = [];
  const flush = () => {
    if (para.length) blocks.push({ type: 'p', lines: para });
    if (list.length) blocks.push({ type: 'ul', items: list });
    para = [];
    list = [];
  };
  for (const raw of md.replace(/\r\n/g, '\n').split('\n')) {
    const line = raw.trimEnd();
    const h = /^(#{1,3})\s+(.*)$/.exec(line.trim());
    if (h) {
      flush();
      const text = h[2].trim();
      blocks.push({ type: (['h1', 'h2', 'h3'] as const)[h[1].length - 1], text, id: slug(text) });
      continue;
    }
    const b = /^\s*[-*]\s+(.*)$/.exec(line);
    if (b) {
      if (para.length) {
        blocks.push({ type: 'p', lines: para });
        para = [];
      }
      list.push(inline(b[1].trim()));
      continue;
    }
    if (!line.trim()) {
      flush();
      continue;
    }
    if (list.length) {
      blocks.push({ type: 'ul', items: list });
      list = [];
    }
    para.push(inline(line.trim()));
  }
  flush();
  return blocks;
}

/** The ## headings, for the table of contents. */
export const contents = (blocks: Block[]) => blocks.filter((b): b is Heading => b.type === 'h2');
