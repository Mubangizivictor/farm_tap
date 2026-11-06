// A short "Today's insights" strip for the Home page (decision 0025). It
// shows the two most serious findings and a link to the AI tools. It stays
// empty while loading, when the AI is off for this person or when there is
// nothing to say, so Home never gets in the way.
import 'dart:async';

import 'package:farm_tap/core/ai/ai_risk.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/sectors/cattle/ai/presentation/ai_widgets.dart';
import 'package:flutter/material.dart';

class AiInsightsStrip extends StatefulWidget {
  const AiInsightsStrip({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  State<AiInsightsStrip> createState() => _AiInsightsStripState();
}

class _AiInsightsStripState extends State<AiInsightsStrip> {
  List<FindingWithState>? _top;
  int _all = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final farm = await widget.ctx.repo.load(role: widget.ctx.role);
      if (!farm.moduleVisible('recommendations')) return;
      final all = farm.findings();
      if (mounted) {
        setState(() {
          _top = todaysInsights(all, 2);
          _all = all.length;
        });
      }
    } on Object {
      // Home must work without the AI strip.
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = _top;
    if (top == null || top.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        aiSection(context, l10n.aiTodaysInsights),
        for (final f in top) ...[FindingCard(item: f, onLink: widget.ctx.onLink), context.space.gapMd],
        if (_all > top.length) TextAction(label: l10n.aiSeeAll(_all), onPressed: () => widget.ctx.onModule('alerts')),
        context.space.gapLg,
      ],
    );
  }
}
