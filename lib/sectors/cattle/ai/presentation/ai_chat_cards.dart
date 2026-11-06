// The cards under a chat answer (decision 0027): the urgency card with the
// message for the vet, the vet's questions, and "which cow is this?".
import 'package:farm_tap/core/ai/ai_chat.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Urgency badge, the "do now" list and the buttons that send the vet a message.
class TriageCard extends StatefulWidget {
  const new({
    required this.triage,
    required this.message,
    required this.vetName,
    required this.onWhatsapp,
    required this.onSharePhoto,
    super.key,
  });

  final Triage triage;
  final String message;
  final String? vetName;
  final VoidCallback onWhatsapp;

  /// Null when no photo was sent.
  final VoidCallback? onSharePhoto;

  @override
  State<TriageCard> createState() => _TriageCardState();
}

class _TriageCardState extends State<TriageCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = widget.triage;
    final tone = switch (t.level) {
      'now' => FarmTapTone.danger,
      'today' => FarmTapTone.warning,
      _ => FarmTapTone.info,
    };
    return FarmTapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FarmTapBanner(tone: tone, icon: Symbols.warning_rounded, title: t.label),
          context.space.gapSm,
          Text(
            l10n.aiChatWhileWaiting,
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          context.space.gapXs,
          for (final d in t.doNow)
            Padding(
              padding: EdgeInsets.only(bottom: context.space.xs),
              child: Text('•  $d', style: context.text.bodyMedium),
            ),
          context.space.gapSm,
          Wrap(
            spacing: context.space.sm,
            runSpacing: context.space.xs,
            children: [
              FilledButton.icon(
                icon: const Icon(Symbols.chat_rounded),
                label: Text(widget.vetName == null ? l10n.aiChatWhatsapp : l10n.aiChatWhatsappName(widget.vetName!)),
                onPressed: widget.onWhatsapp,
              ),
              if (widget.onSharePhoto != null)
                OutlinedButton.icon(
                  icon: const Icon(Symbols.photo_camera_rounded),
                  label: Text(l10n.aiChatSharePhoto),
                  onPressed: widget.onSharePhoto,
                ),
              TextButton.icon(
                icon: const Icon(Symbols.article_rounded),
                label: Text(_open ? l10n.aiChatHideMessage : l10n.aiChatSeeMessage),
                onPressed: () => setState(() => _open = !_open),
              ),
            ],
          ),
          if (_open) ...[
            context.space.gapSm,
            SelectableText(widget.message, style: context.text.bodyMedium),
            TextButton.icon(
              icon: const Icon(Symbols.content_copy_rounded),
              label: Text(l10n.aiChatCopyMessage),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.message));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.aiChatMessageCopied)));
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// The questions a vet asks first. Tapping an answer fills the vet message; the button sends them to the AI.
class CaseCard extends StatefulWidget {
  const new({
    required this.answers,
    required this.animalKnown,
    required this.busy,
    required this.onAnswer,
    required this.onSend,
    super.key,
  });

  final Map<String, String> answers;
  final bool animalKnown;
  final bool busy;
  final void Function(String id, String value) onAnswer;
  final VoidCallback onSend;

  @override
  State<CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<CaseCard> {
  final _temp = TextEditingController();

  @override
  void dispose() {
    _temp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final open = openCaseQuestions(widget.answers, animalKnown: widget.animalKnown);
    if (open.isEmpty && widget.answers.isEmpty) return const SizedBox.shrink();
    return FarmTapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.aiChatVetHelp, style: context.text.titleSmall),
          Text(l10n.aiChatVetHelpHint, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          for (final q in open) ...[
            context.space.gapSm,
            Text(q.label, style: context.text.bodyMedium),
            if (q.options.isNotEmpty)
              Wrap(
                spacing: context.space.sm,
                runSpacing: context.space.xs,
                children: [
                  for (final o in q.options) ActionChip(label: Text(o), onPressed: () => widget.onAnswer(q.id, o)),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _temp,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(hintText: l10n.aiChatTempHint),
                    ),
                  ),
                  context.space.gapSm,
                  OutlinedButton(
                    onPressed: () {
                      final v = cleanTemp(_temp.text);
                      if (v == null) return;
                      widget.onAnswer(q.id, v);
                      _temp.clear();
                    },
                    child: Text(l10n.aiChatAdd),
                  ),
                ],
              ),
          ],
          if (widget.answers.isNotEmpty) ...[
            context.space.gapSm,
            FilledButton.icon(
              icon: const Icon(Symbols.auto_awesome_rounded),
              label: Text(l10n.aiChatUpdateAdvice),
              onPressed: widget.busy ? null : widget.onSend,
            ),
          ],
        ],
      ),
    );
  }
}

/// "Which cow is this?" after a photo or a health answer, so the answer is saved to that cow.
class CowPicker extends StatefulWidget {
  const new({required this.animals, required this.onPick, required this.onSkip, super.key});

  final List<({String id, String label})> animals;
  final void Function(String id) onPick;
  final VoidCallback onSkip;

  @override
  State<CowPicker> createState() => _CowPickerState();
}

class _CowPickerState extends State<CowPicker> {
  String? _id;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.animals.isEmpty) return const SizedBox.shrink();
    return FarmTapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.aiChatWhichCow, style: context.text.titleSmall),
          Text(
            l10n.aiChatWhichCowHint,
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          context.space.gapSm,
          DropdownButton<String>(
            value: _id,
            isExpanded: true,
            hint: Text(l10n.aiChatChooseCow),
            items: [for (final a in widget.animals) DropdownMenuItem(value: a.id, child: Text(a.label))],
            onChanged: (v) => setState(() => _id = v),
          ),
          context.space.gapSm,
          Row(
            children: [
              FilledButton(onPressed: _id == null ? null : () => widget.onPick(_id!), child: Text(l10n.aiChatSave)),
              context.space.gapSm,
              TextButton(onPressed: widget.onSkip, child: Text(l10n.aiChatNotNow)),
            ],
          ),
        ],
      ),
    );
  }
}
