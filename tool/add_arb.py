"""Append strings to app_en.arb and app_nyn.arb (nyn = '[nyn] ' + English).

Usage: python3 tool/add_arb.py strings.json
Each entry is {"key": "text"} or
{"key": {"text": "...", "placeholders": {"n": "int"}}}.
Existing keys are left untouched.
"""
import collections
import json
import sys

EN, NYN = 'lib/core/l10n/app_en.arb', 'lib/core/l10n/app_nyn.arb'
new = json.load(open(sys.argv[1]), object_pairs_hook=collections.OrderedDict)
for path, prefix in ((EN, ''), (NYN, '[nyn] ')):
    d = json.load(open(path), object_pairs_hook=collections.OrderedDict)
    for k, v in new.items():
        if k in d:
            continue
        text, ph = (v['text'], v.get('placeholders', {})) if isinstance(v, dict) else (v, {})
        d[k] = prefix + text
        if ph and path == EN:
            d['@' + k] = {'placeholders': {n: {'type': t} for n, t in ph.items()}}
    with open(path, 'w') as f:
        json.dump(d, f, indent=2, ensure_ascii=False)
        f.write('\n')
