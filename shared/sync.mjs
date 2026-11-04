// Copies shared/*.ts into webapp/src/shared and functions/src/shared.
// --check: exit 1 when a copy differs (used by the tests).
import { readFileSync, readdirSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');
const targets = [join(root, 'webapp/src/shared'), join(root, 'functions/src/shared')];
const check = process.argv.includes('--check');
const header = '// GENERATED from shared/ by `node shared/sync.mjs`. Edit the file in shared/, not this copy.\n';
let stale = [];
for (const name of readdirSync(here).filter((f) => f.endsWith('.ts') && !f.endsWith('.test.ts'))) {
  const body = header + readFileSync(join(here, name), 'utf8');
  for (const dir of targets) {
    const out = join(dir, name);
    if (check) {
      if (!existsSync(out) || readFileSync(out, 'utf8') !== body) stale.push(out);
    } else {
      mkdirSync(dir, { recursive: true });
      writeFileSync(out, body);
    }
  }
}
if (check && stale.length) {
  console.error(`Out of date (run node shared/sync.mjs):\n${stale.join('\n')}`);
  process.exit(1);
}
