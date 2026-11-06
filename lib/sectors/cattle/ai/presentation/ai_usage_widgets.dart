// The AI allowance meter and the AI error banner (decision 0028). Numbers
// come from the server (aiUsageNow and every server answer), or on the pilot
// route from this farm's AI log. Built-in answers never change them.
// Wording lives in core/ai/ai_quota.dart next to the web's, so phone and web
// say the same thing; move it to the ARB files with the next l10n pass.
import 'package:farm_tap/core/ai/ai_quota.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

const aiUsageTitle = 'AI assistant usage';
const aiUsageUnlimited = 'Built-in farm answers: unlimited';
const aiUsageUsed = 'AI requests used';
const aiUsageRemaining = 'Remaining requests';
const aiUsageReset = 'Reset time';
const aiUsageMidnight = 'Midnight';
const aiUsagePilot = 'Counted on this farm’s devices while the secure server is being set up.';
const aiUsageFree =
    'Questions about your records, milk, breeding, feed and money are answered by FarmTap’s built-in intelligence. They are free and never count here.';

class AiUsageMeter extends StatelessWidget {
  const new({required this.view, required this.trusted, super.key});
  final UsageView view;
  final bool trusted;

  @override
  Widget build(BuildContext context) {
    final warn = usageWarning(view);
    final bar = switch (view.level) {
      UsageLevel.out => context.status.danger,
      UsageLevel.warn => context.status.warning,
      UsageLevel.ok => context.colors.primary,
    };
    Widget cell(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          Text(value, style: context.text.titleMedium?.copyWith(fontWeight: FarmTapWeights.semiBold)),
        ],
      ),
    );
    return Semantics(
      label: '$aiUsageTitle: ${view.used} of ${view.limit}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: context.radii.card,
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Padding(
          padding: context.space.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: context.space.sm,
                children: [
                  Text(
                    aiUsageTitle.toUpperCase(),
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FarmTapWeights.bold,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    aiUsageUnlimited,
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
              context.space.gapSm,
              ClipRRect(
                borderRadius: context.radii.chip,
                child: LinearProgressIndicator(
                  value: view.limit == 0 ? 1 : view.used / view.limit,
                  color: bar,
                  backgroundColor: context.colors.surfaceContainerHighest,
                  minHeight: context.space.sm,
                ),
              ),
              context.space.gapSm,
              Row(
                children: [
                  cell(aiUsageUsed, '${view.used}/${view.limit}'),
                  cell(aiUsageRemaining, '${view.remaining}'),
                  cell(aiUsageReset, aiUsageMidnight),
                ],
              ),
              if (!trusted) ...[
                context.space.gapSm,
                Text(aiUsagePilot, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
              ],
              if (warn != null) ...[
                context.space.gapSm,
                FarmTapBanner(
                  tone: view.level == UsageLevel.out ? FarmTapTone.danger : FarmTapTone.warning,
                  icon: view.level == UsageLevel.out ? Symbols.error_rounded : Symbols.flag_rounded,
                  title: warn.title,
                  message: warn.message,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The 80% / 100% line above the message box.
class AiUsageWarning extends StatelessWidget {
  const new({required this.view, super.key});
  final UsageView view;

  @override
  Widget build(BuildContext context) {
    final w = usageWarning(view);
    if (w == null) return const SizedBox.shrink();
    return FarmTapBanner(
      tone: view.level == UsageLevel.out ? FarmTapTone.danger : FarmTapTone.warning,
      icon: view.level == UsageLevel.out ? Symbols.error_rounded : Symbols.flag_rounded,
      title: w.title,
      message: w.message,
    );
  }
}

/// A friendly banner for a failed AI request. No technical details.
class AiErrorBanner extends StatelessWidget {
  const new({required this.kind, required this.limit, super.key});
  final AiErrorKind kind;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final e = aiErrorText(kind, limit: limit);
    return FarmTapBanner(
      tone: kind == AiErrorKind.limit || kind == AiErrorKind.disabled ? FarmTapTone.info : FarmTapTone.warning,
      icon: kind == AiErrorKind.network ? Symbols.wifi_off_rounded : Symbols.info_rounded,
      title: e.title,
      message: e.message,
    );
  }
}
