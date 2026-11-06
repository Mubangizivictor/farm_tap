// Disease Screening (decision 0025, experimental). No licensed, validated
// photo model exists for these checks, so none is installed and FarmTap does
// not claim to detect any of them. What runs here is a plain photo-quality
// check so the photo kept for the vet is usable.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:farm_tap/core/ai/ai_core.dart';
import 'package:farm_tap/core/ai/ai_screening.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/sectors/cattle/ai/presentation/ai_widgets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

class AiScreeningPage extends StatefulWidget {
  const AiScreeningPage({required this.ctx, super.key});

  final AiPageContext ctx;

  @override
  State<AiScreeningPage> createState() => _AiScreeningPageState();
}

class _AiScreeningPageState extends State<AiScreeningPage> {
  PhotoQuality? _quality;
  bool _failed = false;
  bool _busy = false;

  Future<void> _check(ImageSource source) async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1080, imageQuality: 85);
      if (picked == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final bytes = await picked.readAsBytes();
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
      final q = photoQuality(gray, w, h);
      unawaited(widget.ctx.repo.log('screening', ok: true, ms: 0, method: Method.experimental));
      if (mounted) {
        setState(() {
          _quality = q;
          _busy = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _failed = true;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = _quality;
    return AdaptiveScaffold(
      title: aiModuleLabel('screening'),
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AiNote(l10n.aiScreeningNote, icon: Symbols.science_rounded, tone: FarmTapTone.gold),
          context.space.gapLg,
          FarmTapCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.aiPhotoCheckTitle, style: context.text.titleSmall),
                context.space.gapXs,
                Text(l10n.aiPhotoCheckBody, style: context.text.bodyMedium),
                context.space.gapMd,
                FarmTapButton(
                  label: l10n.takePhoto,
                  icon: Symbols.photo_camera_rounded,
                  loading: _busy,
                  onPressed: _busy ? null : () => unawaited(_check(ImageSource.camera)),
                ),
                context.space.gapSm,
                FarmTapButton(
                  label: l10n.chooseFromGallery,
                  icon: Symbols.photo_library_rounded,
                  kind: ButtonKind.outlined,
                  onPressed: _busy ? null : () => unawaited(_check(ImageSource.gallery)),
                ),
                if (_failed) ...[
                  context.space.gapSm,
                  AiNote(l10n.aiPhotoFailed, icon: Symbols.error_rounded, tone: FarmTapTone.danger),
                ],
                if (q != null) ...[
                  context.space.gapMd,
                  if (q.ok)
                    AiNote(l10n.aiPhotoGood, icon: Symbols.check_circle_rounded, tone: FarmTapTone.success)
                  else
                    FarmTapBanner(
                      tone: FarmTapTone.warning,
                      icon: Symbols.warning_rounded,
                      title: l10n.aiPhotoRetake,
                      message: q.problems.join('\n'),
                    ),
                  context.space.gapSm,
                  Text(
                    l10n.aiPhotoNumbers(q.brightness, q.contrast, q.sharpness),
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          context.space.gapLg,
          ListCard(
            title: l10n.aiScreeningTargets,
            children: [
              for (final t in screeningTargets)
                RecordTile(
                  leading: IconBubble(
                    icon: Symbols.photo_camera_rounded,
                    tone: FarmTapTone.neutral,
                    size: context.sizes.bubbleMd,
                  ),
                  title: t.label,
                  subtitle: '${t.photo}\n${t.note}',
                  badge: StatusBadge(label: l10n.aiNoModel, tone: FarmTapTone.neutral),
                  showChevron: false,
                ),
            ],
          ),
          context.space.gapMd,
          AiNote(l10n.aiScreeningPromise),
        ],
      ),
    );
  }
}
