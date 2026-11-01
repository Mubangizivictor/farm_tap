## Theme rules (add to AGENTS.md / CLAUDE.md)

- Import styling only via `package:farm_tap/core/theme/theme.dart`.
- Colours: use `context.colors.*` (Material roles) or `context.status.*` (FarmTap roles). Never `Color(0x..)`, `Colors.*` (except `Colors.transparent`) or `FarmTapPalette` outside `lib/core/theme/`.
- Text: use `context.text.*` or `context.textStyles.*`. Never set `fontSize`, `fontFamily` or `FontWeight.wNNN`; use `.copyWith(fontWeight: FarmTapWeights.bold)` if needed.
- Spacing: `context.space.*` (values, `gapXx`, ready `EdgeInsets`). Never numeric `EdgeInsets`/`SizedBox`.
- Corners: `context.radii.*`. Sizes: `context.sizes.*`. Animation: `context.motion.*`.
- Prefer plain Material widgets (FilledButton, TextField, Card, ListTile) and let the theme style them; do not pass style parameters unless a token requires it.
- New design values go into `lib/core/theme/` as named tokens, in both light and dark mode.
- Do not edit `farmtap_design.dart` values unless the task says so.
- `test/core/theme/theme_guard_test.dart` must pass.
