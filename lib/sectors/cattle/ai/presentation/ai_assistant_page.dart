// Farm Assistant (decision 0025): ask a question, get an answer worked out
// exactly from the farm's records, with the method shown. No AI service is
// called; the same rules as the web app answer here, offline.
import 'dart:async';

import 'package:farm_tap/core/ai/ai_assistant.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/ai/presentation/ai_widgets.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _question = TextEditingController();
  Answer? _answer;
  String _asked = '';

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _ask(String q) async {
    final text = q.trim();
    if (text.isEmpty) return;
    final clock = context.clock;
    final started = clock.now();
    final farm = await widget.ctx.repo.load(role: widget.ctx.role);
    final a = ask(text, farm.data, role: widget.ctx.role, cfg: farm.config);
    unawaited(
      widget.ctx.repo.log('assistant', ok: a.ok, ms: clock.now().difference(started).inMilliseconds, method: a.method),
    );
    if (!mounted) return;
    setState(() {
      _asked = text;
      _answer = a;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctx = widget.ctx;
    final a = _answer;
    return AdaptiveScaffold(
      title: aiModuleLabel('assistant'),
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AiNote(l10n.aiAssistantNote, icon: Symbols.forum_rounded),
          context.space.gapMd,
          FarmTapTextField(
            label: l10n.aiAskLabel,
            hint: l10n.aiAskHint,
            controller: _question,
            icon: Symbols.search_rounded,
            textInputAction: TextInputAction.send,
            onSubmitted: (q) => unawaited(_ask(q)),
          ),
          context.space.gapSm,
          FarmTapButton(
            label: l10n.aiAskButton,
            icon: Symbols.send_rounded,
            onPressed: () => unawaited(_ask(_question.text)),
          ),
          context.space.gapLg,
          if (a != null) ...[
            FarmTapCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_asked, style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                  context.space.gapXs,
                  Text(a.text, style: context.text.titleSmall),
                  if (a.bullets.isNotEmpty) ...[
                    context.space.gapSm,
                    for (final b in a.bullets)
                      Padding(
                        padding: EdgeInsets.only(bottom: context.space.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•  ', style: context.text.bodyMedium),
                            Expanded(child: Text(b, style: context.text.bodyMedium)),
                          ],
                        ),
                      ),
                  ],
                  context.space.gapSm,
                  Wrap(
                    spacing: context.space.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      MethodBadge(a.method),
                      for (final link in a.links.take(3))
                        TextAction(label: link.label, small: true, onPressed: () => ctx.onLink(link.href)),
                    ],
                  ),
                ],
              ),
            ),
            context.space.gapLg,
          ],
          aiSection(
            context,
            l10n.aiTryAsking,
            children: [
              Wrap(
                spacing: context.space.sm,
                runSpacing: context.space.sm,
                children: [
                  for (final q in suggestedQuestions)
                    FarmTapChip(
                      label: q,
                      selected: false,
                      onTap: () {
                        _question.text = q;
                        unawaited(_ask(q));
                      },
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
