// Switches the server jobs on (or off) in platform/config.server after the
// Blaze upgrade (decision 0024). Run by tool/activate-blaze.sh; also usable alone:
//
//   node scripts/activate.mjs                 # all on
//   node scripts/activate.mjs off             # all off
//   node scripts/activate.mjs alerts billingPdf   # only these on
//   node scripts/activate.mjs --show          # show the switches
//
// Uses Google application default credentials
// (`gcloud auth application-default login`, once).
const { initializeApp, applicationDefault } = await import('firebase-admin/app');
const { getFirestore, FieldValue } = await import('firebase-admin/firestore');

const ALL = ['alerts', 'autoSms', 'whatsappApi', 'billingPdf', 'refundsApi', 'accountErase'];
const args = process.argv.slice(2);
const projectId = process.env.FARMTAP_PROJECT ?? 'farm-tap-1dd15';

initializeApp({ credential: applicationDefault(), projectId });
const ref = getFirestore().doc('platform/config');

if (args.includes('--show')) {
  const s = (await ref.get()).get('server') ?? {};
  for (const k of ALL) console.log(`${s[k] === true ? 'ON ' : 'off'}  ${k}`);
  process.exit(0);
}

const off = args[0] === 'off';
const picked = off ? ALL : args.length ? args : ALL;
for (const k of picked) {
  if (!ALL.includes(k)) {
    console.error(`Unknown switch "${k}". Use: ${ALL.join(', ')}`);
    process.exit(1);
  }
}
const server = Object.fromEntries(picked.map((k) => [k, !off]));
await ref.set(
  { server, lastAudit: { by: 'activate-blaze', action: off ? 'server jobs off' : 'server jobs on', at: FieldValue.serverTimestamp() } },
  { merge: true },
);
const now = (await ref.get()).get('server') ?? {};
for (const k of ALL) console.log(`${now[k] === true ? 'ON ' : 'off'}  ${k}`);
