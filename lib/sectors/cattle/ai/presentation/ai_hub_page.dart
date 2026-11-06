// AI Intelligence home (decision 0025, phone phase 2): today's insights and
// the list of AI tools this person may open.
import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_risk.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/sectors/cattle/ai/presentation/ai_widgets.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AiHubPage extends StatelessWidget {
  const AiHubPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AiBody(
      repo: ctx.repo,
      role: ctx.role,
      title: l10n.aiTitle,
      builder: (context, farm, reload) {
        final all = farm.findings();
        final insights = todaysInsights(all, farm.config.insightsCount);
        final modules = [
          for (final m in aiModules)
            if (farm.moduleVisible(m.key) && m.key != 'recommendations') m,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AiNote(l10n.aiIntro, icon: Symbols.auto_awesome_rounded),
            context.space.gapLg,
            if (farm.moduleVisible('recommendations')) ...[
              aiSection(context, l10n.aiTodaysInsights),
              if (insights.isEmpty)
                FarmTapCard(child: Text(l10n.aiNothingBody, style: context.text.bodyMedium))
              else ...[
                for (final f in insights) ...[FindingCard(item: f, onLink: ctx.onLink), context.space.gapMd],
                if (all.length > insights.length)
                  TextAction(label: l10n.aiSeeAll(all.length), onPressed: () => ctx.onModule('alerts')),
              ],
              context.space.gapLg,
            ],
            aiSection(
              context,
              l10n.aiTools,
              children: [
                ListCard(
                  children: [
                    for (final m in modules)
                      RecordTile(
                        leading: IconBubble(
                          icon: moduleIcon(m.key),
                          tone: m.key == 'screening' ? FarmTapTone.gold : FarmTapTone.primary,
                          size: context.sizes.bubbleMd,
                        ),
                        title: m.label,
                        subtitle: m.hint,
                        badge: m.key == 'screening'
                            ? StatusBadge(label: methodLabel[Method.experimental]!, tone: FarmTapTone.gold)
                            : null,
                        onTap: () => ctx.onModule(m.key),
                      ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
