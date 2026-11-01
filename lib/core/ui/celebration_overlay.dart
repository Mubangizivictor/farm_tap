import 'dart:async';

import 'package:farm_tap/core/sound/sound_service.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/animation_view.dart';
import 'package:farm_tap/core/ui/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CelebrationAction { primary, secondary, autoAdvanced }

/// Milk saved, calf born, treatment saved, pregnancy confirmed, payment
/// received, setup complete. Full screen on phones, dialog on wider screens.
/// Plays once (about 1.8 s) then shows its buttons. With [autoAdvance]
/// (milk / delivery flows) the buttons are visible at once and the overlay
/// closes itself after 2 s with [CelebrationAction.autoAdvanced].
Future<CelebrationAction?> showCelebration(
  BuildContext context, {
  required FarmTapAnimation animation,
  required String title,
  required String primaryLabel,
  String? message,
  IconData? primaryIcon,
  String? secondaryLabel,
  ButtonKind secondaryKind = ButtonKind.outlined,
  Widget? summary,
  bool autoAdvance = false,
  FarmTapSound sound = FarmTapSound.celebrate,
}) {
  Widget content(BuildContext ctx) => CelebrationOverlay(
    animation: animation,
    title: title,
    message: message,
    primaryLabel: primaryLabel,
    primaryIcon: primaryIcon,
    secondaryLabel: secondaryLabel,
    secondaryKind: secondaryKind,
    summary: summary,
    autoAdvance: autoAdvance,
    sound: sound,
    onResult: (a) => Navigator.of(ctx).pop(a),
  );
  if (context.isCompact) {
    return Navigator.of(context).push<CelebrationAction>(
      PageRouteBuilder<CelebrationAction>(
        fullscreenDialog: true,
        transitionDuration: context.motion.normal,
        reverseTransitionDuration: context.motion.fast,
        pageBuilder: (ctx, _, _) => content(ctx),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }
  return showDialog<CelebrationAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ctx.sizes.dialogMaxWidth),
        child: content(ctx),
      ),
    ),
  );
}

class CelebrationOverlay extends StatefulWidget {
  const new({
    required this.animation,
    required this.title,
    required this.primaryLabel,
    required this.onResult,
    super.key,
    this.message,
    this.primaryIcon,
    this.secondaryLabel,
    this.secondaryKind = ButtonKind.outlined,
    this.summary,
    this.autoAdvance = false,
    this.sound = FarmTapSound.celebrate,
    this.revealButtons = false,
  });

  final FarmTapAnimation animation;
  final String title;
  final String? message;
  final String primaryLabel;
  final IconData? primaryIcon;
  final String? secondaryLabel;

  /// outlined (default) or text for a quiet "Done".
  final ButtonKind secondaryKind;

  /// Optional summary card under the message (e.g. totals).
  final Widget? summary;
  final bool autoAdvance;

  /// Show the buttons at once (goldens, tests).
  final bool revealButtons;

  /// celebrate by default; pop for milk saved, coin for payment received.
  final FarmTapSound sound;
  final ValueChanged<CelebrationAction> onResult;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  Timer? _reveal;
  Timer? _advance;
  late bool _buttons = widget.autoAdvance || widget.revealButtons;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    unawaited(HapticFeedback.mediumImpact());
    unawaited(SoundService.instance.play(widget.sound));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reveal != null || _advance != null) return;
    if (widget.autoAdvance) {
      _advance = Timer(context.motion.autoAdvance, () => _finish(CelebrationAction.autoAdvanced));
    } else {
      _reveal = Timer(context.motion.celebration, () {
        if (mounted) setState(() => _buttons = true);
      });
    }
  }

  void _finish(CelebrationAction action) {
    if (_done || !mounted) return;
    _done = true;
    _advance?.cancel();
    widget.onResult(action);
  }

  @override
  void dispose() {
    _reveal?.cancel();
    _advance?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final body = Padding(
      padding: context.space.sheet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: FarmTapAnimationView(animation: widget.animation, size: context.sizes.animationCelebration),
          ),
          context.space.gapXl,
          Semantics(
            liveRegion: true,
            child: Text(widget.title, textAlign: TextAlign.center, style: context.text.headlineSmall),
          ),
          if (widget.message != null) ...[
            context.space.gapSm,
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
          if (widget.summary != null) ...[context.space.gapLg, widget.summary!],
          context.space.gapXl,
          AnimatedOpacity(
            opacity: _buttons ? 1 : 0,
            duration: context.motion.normal,
            child: IgnorePointer(
              ignoring: !_buttons,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FarmTapButton(
                    label: widget.primaryLabel,
                    icon: widget.primaryIcon,
                    large: compact,
                    onPressed: () => _finish(CelebrationAction.primary),
                  ),
                  if (widget.secondaryLabel != null) ...[
                    SizedBox(height: context.space.keyGap),
                    FarmTapButton(
                      label: widget.secondaryLabel!,
                      kind: widget.secondaryKind,
                      onPressed: () => _finish(CelebrationAction.secondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (!compact) return body;
    return Scaffold(
      body: SafeArea(
        // Phones: content sits in the upper part, buttons within thumb reach.
        child: Align(alignment: Alignment(0, context.sizes.celebrationAlignY), child: SingleChildScrollView(child: body)),
      ),
    );
  }
}
