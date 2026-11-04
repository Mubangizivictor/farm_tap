// Binding rule 6 on the web (decision 0017): colours, sizes, fonts and
// durations live only in src/theme/. Fails the check if any other source
// file hard-codes one. Media-query widths are allowed (CSS can't use vars).
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

const root = new URL('../src/', import.meta.url).pathname;
const rules = [
  [/#[0-9a-fA-F]{3,8}\b(?![-\w])/, 'hex colour'],
  [/\b(rgb|rgba|hsl|hsla)\(/, 'colour function'],
  [/\b\d+(\.\d+)?px\b/, 'px size'],
  [/\b\d+(\.\d+)?rem\b/, 'rem size'],
  [/\b\d+ms\b/, 'duration'],
  [/font-family\s*:(?!\s*var\()/, 'font family'],
  [/font-size\s*:(?!\s*var\()/, 'font size'],
];

const bad = [];
function walk(dir) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) {
      // shared/ is generated from ../shared (PDF page layout in points, like print).
      if (name !== 'theme' && name !== 'shared') walk(p);
      continue;
    }
    if (!/\.(css|tsx?|mjs)$/.test(name) || name.endsWith('.test.ts')) continue;
    readFileSync(p, 'utf8').split('\n').forEach((line, i) => {
      if (/@media/.test(line) || /theme-guard: ignore/.test(line)) return;
      for (const [re, what] of rules) {
        if (re.test(line)) bad.push(`${relative(root, p)}:${i + 1}  ${what}: ${line.trim()}`);
      }
    });
  }
}
walk(root);
if (bad.length) {
  console.error(`Hard-coded design values outside src/theme/ (use tokens.css):\n${bad.join('\n')}`);
  process.exit(1);
}
console.log('Theme tokens: OK');
