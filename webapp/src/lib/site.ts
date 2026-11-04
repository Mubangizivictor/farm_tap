// The public website's words (decision 0024): the landing page reads
// platform/site, edited in the control panel (Website). Pure, testable.

export interface SiteFeature {
  icon: string;
  title: string;
  text: string;
}
export interface SiteQuestion {
  q: string;
  a: string;
}
export interface SiteContent {
  heroTitle: string;
  heroText: string;
  ctaLabel: string;
  features: SiteFeature[];
  steps: string[];
  faq: SiteQuestion[];
  showPrices: boolean;
  priceNote: string;
  contactTitle: string;
  contactText: string;
  /** Google Play and App Store links once the apps are published (empty hides the badge). */
  playUrl: string;
  appStoreUrl: string;
}

export const defaultSite: SiteContent = {
  heroTitle: 'Farm records that work in your hand',
  heroText:
    'FarmTap keeps your milk, herd, health, feeds, workers and money in one place, on your phone even without internet, and on the web. Made in Mbarara for farms and collection centres in Uganda.',
  ctaLabel: 'Start your free trial',
  features: [
    { icon: 'milk', title: 'Milk every day', text: 'Record milk per cow or for the whole herd in seconds. See trends, sales and what buyers owe you.' },
    { icon: 'health', title: 'Health and withdrawal', text: 'Treatments, vaccinations and drug withdrawal dates, so treated milk never reaches the centre.' },
    { icon: 'calendar', title: 'Reminders that come to you', text: 'Duties, vaccinations, calving and heat reminders on the phone, WhatsApp or SMS.' },
    { icon: 'workers', title: 'Workers and duty roster', text: 'ID cards with QR, clock in and out, pay, and who stands in when someone is away.' },
    { icon: 'farmers', title: 'Collection centres', text: 'Receive milk by card, send receipts, pay farmers and print statements.' },
    { icon: 'money', title: 'Money and reports', text: 'Every cost linked to its work. Profit, cost of a litre and monthly reports in PDF or Excel.' },
  ],
  steps: ['Sign in with Google, Apple or email', 'Set up your farm in 2 minutes', 'Record from day one: the first {trialDays} days are free'],
  faq: [
    { q: 'Does FarmTap work without internet?', a: 'Yes. The phone app saves everything on the phone and sends it when the network comes back.' },
    { q: 'Can my workers use it?', a: 'Yes. Each worker gets a card and a PIN, and only sees the work you allow.' },
    { q: 'How do I pay?', a: 'With MTN Mobile Money, Airtel Money or card, inside the app. You get a receipt every time.' },
    { q: 'What happens when the trial ends?', a: 'Your records stay safe and you can still look at them. Choose a plan to keep adding records.' },
  ],
  showPrices: true,
  priceNote: 'Prices in Uganda shillings. One plan covers one farm or collection centre, with all its workers.',
  contactTitle: 'Talk to us',
  contactText: 'Questions, a demo on your farm, or help getting started: call or WhatsApp us.',
  playUrl: '',
  appStoreUrl: '',
};

const obj = (v: unknown): Record<string, unknown> => (v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : {});
const str = (v: unknown, d: string) => (typeof v === 'string' && v.trim() !== '' ? v : d);

export function siteFromDoc(data: unknown): SiteContent {
  const d = obj(data);
  const D = defaultSite;
  const features = Array.isArray(d.features)
    ? d.features.map(obj).filter((f) => typeof f.title === 'string' && f.title.trim()).map((f) => ({ icon: str(f.icon, 'check'), title: String(f.title), text: str(f.text, '') }))
    : D.features;
  const faq = Array.isArray(d.faq) ? d.faq.map(obj).filter((f) => typeof f.q === 'string' && f.q.trim()).map((f) => ({ q: String(f.q), a: str(f.a, '') })) : D.faq;
  const steps = Array.isArray(d.steps) ? d.steps.filter((s): s is string => typeof s === 'string' && s.trim() !== '') : D.steps;
  return {
    heroTitle: str(d.heroTitle, D.heroTitle),
    heroText: str(d.heroText, D.heroText),
    ctaLabel: str(d.ctaLabel, D.ctaLabel),
    features: features.length ? features.slice(0, 12) : D.features,
    steps: steps.length ? steps.slice(0, 6) : D.steps,
    faq: faq.slice(0, 20),
    showPrices: typeof d.showPrices === 'boolean' ? d.showPrices : D.showPrices,
    priceNote: typeof d.priceNote === 'string' ? d.priceNote : D.priceNote,
    contactTitle: str(d.contactTitle, D.contactTitle),
    contactText: str(d.contactText, D.contactText),
    playUrl: typeof d.playUrl === 'string' ? d.playUrl : '',
    appStoreUrl: typeof d.appStoreUrl === 'string' ? d.appStoreUrl : '',
  };
}

/** Company details on documents (platform/company). */
export interface Company {
  company: string;
  address: string;
  website: string;
  tin: string;
  signatoryName: string;
  signatoryTitle: string;
}

export function companyFromDoc(data: unknown, defaults: Company): Company {
  const d = obj(data);
  return {
    company: str(d.company, defaults.company),
    address: str(d.address, defaults.address),
    website: str(d.website, defaults.website),
    tin: typeof d.tin === 'string' ? d.tin : defaults.tin,
    signatoryName: str(d.signatoryName, defaults.signatoryName),
    signatoryTitle: str(d.signatoryTitle, defaults.signatoryTitle),
  };
}

export const telHref = (p: string) => `tel:${p.replace(/[^\d+]/g, '')}`;
export const waHref = (p: string, text = 'Hello FarmTap') => `https://wa.me/${p.replace(/\D/g, '')}?text=${encodeURIComponent(text)}`;
