// Veterinary Assistant (decision 0025): tick what you see, get possible
// causes, warning signs and when to call the vet. A guide, never a
// diagnosis, a drug or a dose. A saved result goes to the animal's health
// history (healthAssessments, append-only), the same record the web writes.
import 'dart:async';

import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_repository.dart';
import 'package:farm_tap/core/ai/ai_vet.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/ai/presentation/ai_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

class AiVetPage extends StatefulWidget {
  const new({required this.ctx, super.key, this.animalId});

  final AiPageContext ctx;

  /// Opened from an animal's page.
  final String? animalId;

  @override
  State<AiVetPage> createState() => _AiVetPageState();
}

class _AiVetPageState extends State<AiVetPage> {
  final _picked = <String>{};
  final _temp = TextEditingController();
  final _days = TextEditingController();
  final _note = TextEditingController();
  late String? _animalId = widget.animalId;
  VetResult? _result;
  bool _saving = false;
  bool _saved = false;
  String? _tempError;

  @override
  void dispose() {
    _temp.dispose();
    _days.dispose();
    _note.dispose();
    super.dispose();
  }

  String _label(Rec a) {
    final tag = a.str('tagNumber');
    final name = animalName(a);
    return tag == null || tag.isEmpty || name == tag ? name : '$name · $tag';
  }

  double? get _tempC {
    final t = _temp.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  int? get _daysSeen => int.tryParse(_days.text.trim());

  void _check(AppLocalizations l10n, AiFarm farm) {
    final t = _tempC;
    if (_temp.text.trim().isNotEmpty && (t == null || t < 30 || t > 45)) {
      setState(() => _tempError = l10n.aiTempNeeded);
      return;
    }
    final started = context.clock.now();
    final dsc = _animalId == null ? null : breedingState(_animalId!, farm.data.breeding, today(farm.data)).daysInMilk;
    final r = assess(VetInput(signs: _picked.toList(), tempC: t, daysSinceCalving: dsc, days: _daysSeen));
    unawaited(
      widget.ctx.repo.log(
        'vet',
        ok: true,
        ms: context.clock.now().difference(started).inMilliseconds,
        method: Method.rules,
      ),
    );
    setState(() {
      _tempError = null;
      _result = r;
      _saved = false;
    });
  }

  Future<void> _save(AiFarm farm, VetResult r) async {
    final id = _animalId;
    if (id == null) return;
    setState(() => _saving = true);
    final dsc = breedingState(id, farm.data.breeding, today(farm.data)).daysInMilk;
    await widget.ctx.repo.saveAssessment({
      'animalId': id,
      'kind': 'vet',
      'signs': _picked.toList(),
      'tempC': _tempC,
      'daysSinceCalving': dsc,
      'days': _daysSeen,
      'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
      'photo': null,
      'risk': r.risk.name,
      'possible': [for (final p in r.possible) p.name],
      'redFlags': r.redFlags,
      'callVet': r.callVet,
      'engine': vetEngine,
      'model': null,
    });
    if (mounted) {
      setState(() {
        _saving = false;
        _saved = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctx = widget.ctx;
    return AiBody(
      repo: ctx.repo,
      role: ctx.role,
      title: aiModuleLabel('vet'),
      builder: (context, farm, reload) {
        final animals = alive(farm.data.animals).where(isActive).toList();
        final selected = animals.where((a) => a.id == _animalId).firstOrNull;
        final groups = <String>[
          ...{for (final s in signs) s.group},
        ];
        final r = _result;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AiNote(vetDisclaimer, icon: Symbols.shield_rounded),
            context.space.gapLg,
            FarmTapCard(
              onTap: () async {
                final labels = {for (final a in animals) _label(a): a.id};
                final pick = await showSearchPicker(
                  context,
                  title: l10n.aiWhichAnimal,
                  options: labels.keys.toList(),
                  selected: selected == null ? null : _label(selected),
                );
                if (pick != null && labels.containsKey(pick)) setState(() => _animalId = labels[pick]);
              },
              child: Row(
                children: [
                  Icon(Symbols.pets_rounded, color: context.colors.primary),
                  context.space.gapMd,
                  Expanded(
                    child: Text(
                      selected == null ? l10n.aiChooseAnimal : _label(selected),
                      style: context.text.bodyLarge,
                    ),
                  ),
                  Icon(Symbols.expand_more_rounded, color: context.colors.onSurfaceVariant),
                ],
              ),
            ),
            context.space.gapLg,
            for (final g in groups) ...[
              SectionLabel(g),
              context.space.gapSm,
              Wrap(
                spacing: context.space.sm,
                runSpacing: context.space.sm,
                children: [
                  for (final s in signs.where((s) => s.group == g))
                    FarmTapChip(
                      label: s.label,
                      selected: _picked.contains(s.key),
                      onTap: () => setState(() {
                        if (!_picked.remove(s.key)) _picked.add(s.key);
                        _result = null;
                      }),
                    ),
                ],
              ),
              context.space.gapLg,
            ],
            FarmTapTextField(
              label: l10n.aiTempOptional,
              controller: _temp,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
              error: _tempError,
              helper: l10n.aiTempHelp,
            ),
            context.space.gapMd,
            FarmTapTextField(
              label: l10n.aiDaysSeen,
              controller: _days,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            context.space.gapMd,
            FarmTapButton(
              label: l10n.aiCheckNow,
              icon: Symbols.stethoscope_rounded,
              onPressed: _picked.isEmpty && _temp.text.trim().isEmpty ? null : () => _check(l10n, farm),
            ),
            if (r != null) ...[
              context.space.gapLg,
              _VetResultCard(result: r),
              context.space.gapMd,
              FarmTapTextField(label: l10n.aiNoteOptional, controller: _note),
              context.space.gapSm,
              if (_saved)
                AiNote(l10n.aiSavedToHistory, icon: Symbols.check_circle_rounded, tone: FarmTapTone.success)
              else
                FarmTapButton(
                  label: _animalId == null ? l10n.aiChooseAnimalToSave : l10n.aiSaveToHistory,
                  kind: ButtonKind.tonal,
                  loading: _saving,
                  onPressed: _animalId == null ? null : () => unawaited(_save(farm, r)),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _VetResultCard extends StatelessWidget {
  const new({required this.result});

  final VetResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tone = severityTone(result.risk);
    final call = switch (result.callVet) {
      'now' => l10n.aiCallVetNow,
      'today' => l10n.aiCallVetToday,
      _ => l10n.aiCallVetSoon,
    };
    return FarmTapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBubble(icon: Symbols.stethoscope_rounded, tone: tone, size: context.sizes.bubbleMd),
              context.space.gapMd,
              Expanded(child: Text(call, style: context.text.titleMedium)),
              const MethodBadge(Method.rules),
            ],
          ),
          if (result.redFlags.isNotEmpty) ...[
            context.space.gapMd,
            FarmTapBanner(
              tone: FarmTapTone.danger,
              icon: Symbols.warning_rounded,
              title: l10n.aiWarningSigns,
              message: result.redFlags.join('\n'),
            ),
          ],
          if (result.possible.isNotEmpty) ...[
            context.space.gapMd,
            Text(l10n.aiPossibleCauses, style: context.text.titleSmall),
            context.space.gapXs,
            for (final p in result.possible) ...[
              Text(p.name, style: context.text.bodyLarge?.copyWith(fontWeight: FarmTapWeights.semiBold)),
              Text(
                p.matched.join(', '),
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              if (p.notifiable)
                Text(l10n.aiMustReport, style: context.text.bodySmall?.copyWith(color: context.colors.error)),
              context.space.gapSm,
            ],
          ],
          context.space.gapSm,
          Text(l10n.aiWhatToDoNow, style: context.text.titleSmall),
          context.space.gapXs,
          for (final s in result.steps)
            Padding(
              padding: EdgeInsets.only(bottom: context.space.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: context.text.bodyMedium),
                  Expanded(child: Text(s, style: context.text.bodyMedium)),
                ],
              ),
            ),
          context.space.gapSm,
          Text(result.disclaimer, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
