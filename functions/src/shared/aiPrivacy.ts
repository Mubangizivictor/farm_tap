// GENERATED from shared/ by `node shared/sync.mjs`. Edit the file in shared/, not this copy.
// FarmTap AI engine — what may leave the farm for an optional self-hosted
// language model (decision 0025, ROADMAP AI-04). Only the question and the
// assistant's own calculated answer are sent, with animal names and tags,
// people's names, phone numbers, emails and places replaced by neutral
// labels. The model is told to rephrase, never to add numbers.

import type { Answer } from './aiAssistant.ts';

const PHONE = /(\+?\d[\d\s-]{7,}\d)/g;
const EMAIL = /[\w.+-]+@[\w-]+\.[\w.]+/g;

/** Replace each known name (animals, staff, farm, place) with a label like "Animal 3". Longest first so "Bella 2" wins over "Bella". */
export function redact(text: string, names: { value: string; label: string }[]): string {
  let out = text.replace(EMAIL, '[email]').replace(PHONE, '[phone]');
  const list = names.filter((n) => n.value && n.value.trim().length >= 2).sort((a, b) => b.value.length - a.value.length);
  for (const n of list) {
    const esc = n.value.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    out = out.replace(new RegExp(`\\b${esc}\\b`, 'gi'), n.label);
  }
  return out;
}

/** Labels for every name on the farm, in a fixed order so the same animal keeps its label. */
export function nameLabels(input: { animals: { name?: string; tagNumber?: string }[]; people: string[]; places: string[] }) {
  const out: { value: string; label: string }[] = [];
  input.animals.forEach((a, i) => {
    if (a.name) out.push({ value: a.name, label: `Animal ${i + 1}` });
    if (a.tagNumber) out.push({ value: a.tagNumber, label: `Animal ${i + 1}` });
  });
  input.people.forEach((p, i) => out.push({ value: p, label: `Person ${i + 1}` }));
  input.places.forEach((p) => out.push({ value: p, label: '[place]' }));
  return out;
}

export const SYSTEM_PROMPT = [
  'You help dairy farmers in Uganda understand their own farm records.',
  'You receive a question and an ANSWER that was calculated exactly from the records.',
  'Rewrite the ANSWER in short, simple English a farmer can read on a phone.',
  'Do not add, change or round any number. Do not add facts, causes, drugs or doses.',
  'If the answer says something cannot be worked out, say so plainly.',
  'For any animal health question, end with: "Call your vet."',
].join(' ');

/** The prompt sent to the model; everything in it has been through redact(). */
export function buildPrompt(question: string, a: Answer, names: { value: string; label: string }[]) {
  const body = [a.text, ...a.bullets.map((b) => `- ${b}`)].join('\n');
  return { system: SYSTEM_PROMPT, user: `QUESTION: ${redact(question, names)}\nANSWER:\n${redact(body, names)}` };
}

/** Put the real names back into the model's reply, on the farm's own device. */
export function restore(text: string, names: { value: string; label: string }[]) {
  let out = text;
  const seen = new Set<string>();
  for (const n of names) {
    if (seen.has(n.label) || n.label === '[place]') continue;
    seen.add(n.label);
    out = out.replace(new RegExp(`\\b${n.label}\\b`, 'g'), n.value);
  }
  return out;
}

/** Numbers in the model's reply that were not in the calculated answer: if any, the reply is thrown away. */
export function inventedNumbers(reply: string, a: Answer): string[] {
  const known = new Set((`${a.text} ${a.bullets.join(' ')}`.match(/\d[\d,]*(\.\d+)?/g) ?? []).map((x) => x.replace(/,/g, '')));
  const plain = reply.replace(/\b(Animal|Person) \d+\b/g, '');
  return (plain.match(/\d[\d,]*(\.\d+)?/g) ?? []).map((x) => x.replace(/,/g, '')).filter((x) => !known.has(x));
}
