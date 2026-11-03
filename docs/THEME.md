# FarmTap Theme System

One control panel, named tokens, light and dark mode automatic.

## Where to change things

| I want to change... | Edit this | Effect |
|---|---|---|
| Size of everything (buttons, icons, keypad, spacing) | `FarmTapDesign.current.sizeScale` in `lib/core/theme/farmtap_design.dart` | Whole app, both modes |
| Size of all text | `FarmTapDesign.current.textScale` | Whole app, both modes |
| Roundness of all corners | `FarmTapDesign.current.radiusScale` | Whole app, both modes |
| Spacing grid | `FarmTapDesign.current.baseUnit` | Whole app, both modes |
| Font | `FarmTapDesign.current.fontFamily` (must be in pubspec) | Whole app |
| A raw colour (e.g. the exact green) | `tokens/farmtap_palette.dart` | Everywhere that colour is used |
| Which colour is "primary", "surface", etc. | `colors/farmtap_color_schemes.dart` | Material components, light and dark |
| Success / warning / danger / sync / withdrawal colours | `colors/farmtap_semantic_colors.dart` | FarmTap widgets, light and dark |
| One specific size (e.g. keypad key) | `tokens/farmtap_sizes.dart` | Every keypad |
| How all buttons / inputs / cards look | `components/farmtap_component_themes.dart` | Every button / input / card |
| Text sizes of a style (e.g. titleLarge) | `typography/farmtap_typography.dart` | Every use of that style |

## Files

```
lib/core/theme/
  theme.dart                       <- import this one file everywhere
  farmtap_design.dart              <- CONTROL PANEL
  farmtap_theme.dart               <- builds light + dark ThemeData (rarely edited)
  farmtap_theme_context.dart       <- context.colors, context.space, ...
  farmtap_assets.dart              <- asset paths
  tokens/
    farmtap_palette.dart           <- the ONLY file with hex colours
    farmtap_spacing.dart
    farmtap_radii.dart
    farmtap_sizes.dart
    farmtap_motion.dart
  colors/
    farmtap_color_schemes.dart     <- Material roles, light + dark
    farmtap_semantic_colors.dart   <- FarmTap roles, light + dark
  typography/
    farmtap_typography.dart        <- TextTheme, FarmTapTextStyles, FarmTapWeights
  components/
    farmtap_component_themes.dart  <- buttons, inputs, cards, dialogs...
```

## How widgets use the theme

```dart
import 'package:farm_tap/core/theme/theme.dart';

class MilkTotalCard extends StatelessWidget {
  const MilkTotalCard({required this.litres, super.key});
  final double litres;

  @override
  Widget build(BuildContext context) {
    return Card(                                   // style comes from the theme
      child: Padding(
        padding: context.space.card,               // not EdgeInsets.all(16)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Milk today', style: context.textStyles.metricLabel),
            context.space.gapXs,                   // not SizedBox(height: 4)
            Text('$litres L', style: context.textStyles.metricValue),
            context.space.gapSm,
            Icon(Icons.check_circle,
                color: context.status.success,     // not Colors.green
                size: context.sizes.iconLg),       // not 28
          ],
        ),
      ),
    );
  }
}
```

## Token cheat sheet

| Access | Values (default design) |
|---|---|
| `context.space.xxs/xs/sm/md/lg/xl/xxl/xxxl` | 2 / 4 / 6 / 8 / 12 / 16 / 24 / 32 (compact, decision 0013) |
| `context.space.gapXs ... gapXxxl` | ready `SizedBox` gaps |
| `context.space.screen / card / listItem / input / button / sheet` | ready `EdgeInsets` |
| `context.radii.xs/sm/md/lg/xl/pill` | 6 / 8 / 12 / 14 / 18 / 999 |
| `context.radii.button / input / card / dialog / sheet / chip / keypadKey` | ready `BorderRadius` |
| `context.sizes.touchTarget / buttonHeight / keypadKey / fab` | 48 / 48 / 56 / 48 |
| `context.sizes.backSwipeEdge` | 20 (iOS back-swipe strip on dirty forms, `DiscardGuard`) |
| `context.sizes.iconXs/Sm/Md/Lg/Xl/Hero` | 14 / 18 / 20 / 22 / 32 / 48 |
| `context.sizes.borderThin/Medium/Thick` | 1 / 1.5 / 2 |
| `context.colors.*` | Material roles: primary, onPrimary, surface, onSurface, outline, error... |
| `context.status.*` | success, warning, danger, info (+ on / container), synced, syncPending, syncFailed, withdrawal, nfcActive, keypadKey, brandGreen, brandGold |
| `context.text.*` | Material text styles (display, headline, title, body, label) |
| `context.textStyles.*` | keypadDigit, keypadDisplay, readBackValue, readBackLabel, metricValue, metricLabel, sectionLabel, tagNumber, button, buttonLarge |
| `FarmTapWeights.*` | regular, medium, semiBold, bold, extraBold |
| `context.motion.*` | fast, normal, slow, splash, snackBar; curves standard, emphasized, exit |

## Rules (enforced by `test/core/theme/theme_guard_test.dart`)

Outside `lib/core/theme/` you may NOT write:

- `Color(0x...)`, `Color.fromARGB`, `Colors.red` (only `Colors.transparent` is allowed)
- `fontSize:`, `fontFamily:`, `FontWeight.w600`
- `BorderRadius.circular(12)`, `EdgeInsets.all(16)`, `SizedBox(height: 8)`
- `Duration(milliseconds: 300)`

`flutter test` fails and lists every violation with file and line.
For a rare, justified exception add `// theme-guard: ignore` on that line.

## Adding a new token

1. Add it to the right file in `tokens/`, `colors/` or `typography/`, in BOTH light and dark where it is a colour.
2. Give it a name that says what it is FOR (`keypadKey`), not what it looks like (`lightGrey`).
3. Use it through `context.*`.
