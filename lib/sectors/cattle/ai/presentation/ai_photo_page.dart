// Photo Check (decision 0026): take a photo, Google Gemini describes what it
// can see and lists possible causes. It covers animal health (skin, eyes,
// udder, hooves, dung, calves) and the rest of the farm (feed, water, pasture,
// sheds). It is never a diagnosis: drugs, doses and certain-sounding
// diagnoses are removed by readPhotoReply, and every health result says to
// call the vet. The words of a result are saved to the farm's health history
// (healthAssessments, append-only); the picture itself is not stored.
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_data.dart';
import 'package:farm_tap/core/ai/ai_photo.dart';
import 'package:farm_tap/core/ai/ai_privacy.dart';
import 'package:farm_tap/core/ai/ai_repository.dart';
import 'package:farm_tap/core/ai/ai_screening.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/sectors/cattle/ai/presentation/ai_widgets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

class AiPhotoPage extends StatefulWidget {
  const new({required this.ctx, super.key, this.animalId});

  final AiPageContext ctx;

  /// Opened from an animal's page.
  final String? animalId;

  @override
  State<AiPhotoPage> createState() => _AiPhotoPageState();
}

class _AiPhotoPageState extends State<AiPhotoPage> {
  PhotoCheck _check = photoChecks.first;
  late String? _animalId = widget.animalId;
  final _note = TextEditingController();
  Uint8List? _bytes;
  String _mime = 'image/jpeg';
  PhotoQuality? _quality;
  bool _reading = false;
  bool _busy = false;
  bool _pickFailed = false;
  PhotoFailure? _failure;
  PhotoResult? _result;
  bool _saved = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _label(Rec a) {
    final tag = a.str('tagNumber');
    final name = animalName(a);
    return tag == null || tag.isEmpty || name == tag ? name : '$name · $tag';
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _reading = true;
      _pickFailed = false;
      _failure = null;
      _result = null;
      _saved = false;
    });
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: photoMaxSide.toDouble(), imageQuality: 82);
      if (picked == null) {
        if (mounted) setState(() => _reading = false);
        return;
      }
      final bytes = await picked.readAsBytes();
      if (bytes.length > photoMaxBytes) throw StateError('too big');
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 320);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final data = await img.toByteData();
      if (data == null) throw StateError('no pixels');
      final w = img.width;
      final h = img.height;
      final gray = List<num>.generate(w * h, (i) {
        final o = i * 4;
        return 0.299 * data.getUint8(o) + 0.587 * data.getUint8(o + 1) + 0.114 * data.getUint8(o + 2);
      });
      final path = picked.path.toLowerCase();
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _mime = path.endsWith('.png')
              ? 'image/png'
              : path.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
          _quality = photoQuality(gray, w, h);
          _reading = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _pickFailed = true;
          _reading = false;
        });
      }
    }
  }

  Future<void> _run(AiFarm farm) async {
    final bytes = _bytes;
    final analyzer = widget.ctx.photo;
    if (bytes == null || analyzer == null) return;
    final started = context.clock.now();
    setState(() {
      _busy = true;
      _failure = null;
      _result = null;
      _saved = false;
    });
    final animals = alive(farm.data.animals);
    final names = nameLabels(
      animals: [for (final a in animals) (name: a.str('name'), tagNumber: a.str('tagNumber'))],
      people: [widget.ctx.byName],
      places: [widget.ctx.farmName],
    );
    final dsc = _animalId == null ? null : breedingState(_animalId!, farm.data.breeding, today(farm.data)).daysInMilk;
    final note = redact(_note.text, names).trim();
    final prompt = buildPhotoPrompt(_check, note: note, daysSinceCalving: dsc);
    final model = farm.config.photoModel;
    try {
      final text = await analyzer.analyze(bytes: bytes, mime: _mime, prompt: prompt, system: photoSystem, model: model);
      final result = readPhotoReply(text, _check);
      final ms = context.clock.now().difference(started).inMilliseconds;
      if (result == null) {
        unawaited(widget.ctx.repo.log('photo', ok: false, ms: ms, method: Method.model));
        if (mounted) {
          setState(() {
            _busy = false;
            _failure = PhotoFailure.unreadable;
          });
        }
        return;
      }
      unawaited(widget.ctx.repo.log('photo', ok: true, ms: ms, method: Method.model));
      // Keep the words of the result (not the picture) for the vet and for the daily limit.
      if (result.usable) {
        unawaited(
          widget.ctx.repo
              .savePhotoAssessment(
                photoAssessmentBody(
                  result,
                  _check,
                  animalId: _animalId,
                  note: note.isEmpty ? null : note,
                  model: model,
                  at: widget.ctx.repo.nowIso,
                ),
              )
              .then((_) {
                if (mounted) setState(() => _saved = true);
              }),
        );
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _result = result;
        });
      }
    } on Object catch (e) {
      unawaited(
        widget.ctx.repo.log(
          'photo',
          ok: false,
          ms: context.clock.now().difference(started).inMilliseconds,
          method: Method.model,
        ),
      );
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = photoFailureOf(e);
        });
      }
    }
  }

  void _reset() => setState(() {
    _bytes = null;
    _quality = null;
    _result = null;
    _failure = null;
    _saved = false;
    _note.clear();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctx = widget.ctx;
    return AiBody(
      repo: ctx.repo,
      role: ctx.role,
      title: aiModuleLabel('screening'),
      builder: (context, farm, reload) {
        final cfg = farm.config;
        final limit = photoAllowed(
          farm.photoUsedToday,
          enabled: cfg.photoEnabled,
          perFarmPerDay: cfg.photoPerFarmPerDay,
        );
        final animals = alive(farm.data.animals).where(isActive).toList();
        final selected = animals.where((a) => a.id == _animalId).firstOrNull;
        final q = _quality;
        final r = _result;
        final ready = ctx.photo != null && cfg.photoEnabled;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AiNote(photoDisclaimer, icon: Symbols.shield_rounded),
            context.space.gapLg,
            if (!ready) ...[
              FarmTapBanner(
                tone: FarmTapTone.warning,
                icon: Symbols.toggle_off_rounded,
                title: l10n.aiPhotoOffTitle,
                message: l10n.aiPhotoOffBody,
              ),
              context.space.gapLg,
            ],
            Text(l10n.aiPhotoWhat, style: context.text.titleSmall),
            context.space.gapSm,
            for (var g = 0; g < photoGroups.length; g++) ...[
              SectionLabel(photoGroups[g]),
              context.space.gapSm,
              Wrap(
                spacing: context.space.sm,
                runSpacing: context.space.sm,
                children: [
                  for (final c in photoChecks.where((c) => c.groupIndex == g))
                    FarmTapChip(
                      label: c.label,
                      selected: _check.key == c.key,
                      onTap: () => setState(() {
                        _check = c;
                        _result = null;
                        _failure = null;
                      }),
                    ),
                ],
              ),
              context.space.gapMd,
            ],
            AiNote('${l10n.aiPhotoHowTo}: ${_check.how}', icon: Symbols.photo_camera_rounded),
            if (_check.kind == PhotoKind.health) ...[
              context.space.gapMd,
              FarmTapCard(
                onTap: () async {
                  final labels = {for (final a in animals) _label(a): a.id};
                  final pick = await showSearchPicker(
                    context,
                    title: l10n.aiWhichAnimal,
                    options: [l10n.aiPhotoNoAnimal, ...labels.keys],
                    selected: selected == null ? null : _label(selected),
                  );
                  if (pick == null) return;
                  setState(() => _animalId = labels[pick]);
                },
                child: Row(
                  children: [
                    Icon(Symbols.pets_rounded, color: context.colors.primary),
                    context.space.gapMd,
                    Expanded(
                      child: Text(
                        selected == null ? l10n.aiPhotoAnimalOpt : _label(selected),
                        style: context.text.bodyLarge,
                      ),
                    ),
                    Icon(Symbols.expand_more_rounded, color: context.colors.onSurfaceVariant),
                  ],
                ),
              ),
            ],
            context.space.gapMd,
            FarmTapTextField(label: l10n.aiPhotoNote, controller: _note, helper: l10n.aiPhotoNoteHint),
            context.space.gapMd,
            FarmTapButton(
              label: l10n.takePhoto,
              icon: Symbols.photo_camera_rounded,
              loading: _reading,
              onPressed: _reading || _busy ? null : () => unawaited(_pick(ImageSource.camera)),
            ),
            context.space.gapSm,
            FarmTapButton(
              label: l10n.chooseFromGallery,
              icon: Symbols.photo_library_rounded,
              kind: ButtonKind.outlined,
              onPressed: _reading || _busy ? null : () => unawaited(_pick(ImageSource.gallery)),
            ),
            if (_pickFailed) ...[
              context.space.gapSm,
              AiNote(l10n.aiPhotoFailed, icon: Symbols.error_rounded, tone: FarmTapTone.danger),
            ],
            if (_bytes != null) ...[
              context.space.gapMd,
              ClipRRect(
                borderRadius: context.radii.card,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.memory(_bytes!, fit: BoxFit.cover),
                ),
              ),
              if (q != null && !q.ok) ...[
                context.space.gapSm,
                FarmTapBanner(
                  tone: FarmTapTone.warning,
                  icon: Symbols.warning_rounded,
                  title: l10n.aiPhotoRetake,
                  message: q.problems.join('\n'),
                ),
              ],
              context.space.gapMd,
              AiNote(l10n.aiPhotoConsent, icon: Symbols.cloud_upload_rounded),
              context.space.gapSm,
              if (ready && limit.ok)
                FarmTapButton(
                  label: q != null && !q.ok ? l10n.aiPhotoCheckAnyway : l10n.aiPhotoRun,
                  icon: Symbols.auto_awesome_rounded,
                  loading: _busy,
                  onPressed: _busy ? null : () => unawaited(_run(farm)),
                )
              else if (ready)
                AiNote(l10n.aiPhotoLimit, icon: Symbols.timer_rounded, tone: FarmTapTone.warning),
              if (ready && limit.ok) ...[
                context.space.gapXs,
                Text(
                  l10n.aiPhotoLeft(limit.left),
                  style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                ),
              ],
            ],
            if (_failure != null) ...[
              context.space.gapMd,
              FarmTapBanner(
                tone: FarmTapTone.danger,
                icon: Symbols.error_rounded,
                title: switch (_failure!) {
                  PhotoFailure.network => l10n.aiPhotoErrNetwork,
                  PhotoFailure.busy => l10n.aiPhotoErrBusy,
                  PhotoFailure.appCheck => l10n.aiPhotoErrAppCheck,
                  PhotoFailure.unreadable => l10n.aiPhotoErrRead,
                },
              ),
            ],
            if (r != null) ...[
              context.space.gapLg,
              _PhotoResultCard(result: r, saved: _saved),
              context.space.gapMd,
              FarmTapButton(
                label: l10n.aiPhotoNewCheck,
                icon: Symbols.refresh_rounded,
                kind: ButtonKind.outlined,
                onPressed: _reset,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PhotoResultCard extends StatelessWidget {
  const new({required this.result, required this.saved});

  final PhotoResult result;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = result;
    final tone = severityTone(r.risk);
    final head = switch (r.callVet) {
      'now' => l10n.aiCallVetNow,
      'today' => l10n.aiCallVetToday,
      'soon' => l10n.aiCallVetSoon,
      _ => r.usable ? l10n.aiPhotoSeen : l10n.aiPhotoRetake,
    };
    String certainty(String c) => switch (c) {
      'clear' => l10n.aiPhotoSure,
      'possible' => l10n.aiPhotoMaybe,
      _ => l10n.aiPhotoUnsure,
    };
    Widget bullets(List<String> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in items)
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
      ],
    );
    return FarmTapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBubble(icon: Symbols.photo_camera_rounded, tone: tone, size: context.sizes.bubbleMd),
              context.space.gapMd,
              Expanded(child: Text(head, style: context.text.titleMedium)),
              const MethodBadge(Method.model),
            ],
          ),
          context.space.gapMd,
          Text(r.summary, style: context.text.bodyLarge),
          if (r.report) ...[
            context.space.gapMd,
            FarmTapBanner(tone: FarmTapTone.danger, icon: Symbols.flag_rounded, title: l10n.aiPhotoReport),
          ],
          if (r.signs.isNotEmpty) ...[
            context.space.gapMd,
            Text(l10n.aiPhotoSeen, style: context.text.titleSmall),
            context.space.gapXs,
            for (final s in r.signs) ...[
              Text(s.what, style: context.text.bodyLarge?.copyWith(fontWeight: FarmTapWeights.semiBold)),
              Text(
                [if (s.where.isNotEmpty) s.where, certainty(s.certainty)].join(' · '),
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              context.space.gapSm,
            ],
          ],
          if (r.possible.isNotEmpty) ...[
            context.space.gapSm,
            Text(l10n.aiPossibleCauses, style: context.text.titleSmall),
            context.space.gapXs,
            for (final p in r.possible) ...[
              Text(p.name, style: context.text.bodyLarge?.copyWith(fontWeight: FarmTapWeights.semiBold)),
              if (p.why.isNotEmpty)
                Text(p.why, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
              context.space.gapSm,
            ],
          ],
          if (r.steps.isNotEmpty) ...[
            context.space.gapSm,
            Text(l10n.aiWhatToDoNow, style: context.text.titleSmall),
            context.space.gapXs,
            bullets(r.steps),
          ],
          if (r.questions.isNotEmpty) ...[
            context.space.gapSm,
            Text(l10n.aiPhotoQuestions, style: context.text.titleSmall),
            context.space.gapXs,
            bullets(r.questions),
          ],
          if (r.retake != null) ...[
            context.space.gapSm,
            AiNote(r.retake!, icon: Symbols.photo_camera_rounded, tone: FarmTapTone.warning),
          ],
          if (saved) ...[
            context.space.gapSm,
            AiNote(l10n.aiPhotoSaved, icon: Symbols.check_circle_rounded, tone: FarmTapTone.success),
          ],
          context.space.gapSm,
          Text(r.disclaimer, style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
