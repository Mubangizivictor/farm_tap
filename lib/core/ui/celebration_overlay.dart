import 'dart:async';

import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/animation_view.dart';
import 'package:farm_tap/core/ui/breakpoints.dart';
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
  bool autoAdvance = false,
}) {
  Widget content(BuildContext ctx) => CelebrationOverlay(
    animation: animation,
    title: title,
    message: message,
    primaryLabel: primaryLabel,
    primaryIcon: primaryIcon,
    secondaryLabel: secondaryLabel,
    autoAdvance: autoAdvance,
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
    this.autoAdvance = false,
  });

  final FarmTapAnimation animation;
  final String title;
  final String? message;
  final String primaryLabel;
  final IconData? primaryIcon;
  final String? secondaryLabel;
  final bool autoAdvance;
  final ValueChanged<CelebrationAction> onResult;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  Timer? _reveal;
  Timer? _advance;
  late bool _buttons = widget.autoAdvance;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    // TODO(audio): play the short success sound (<= 0.5 s, off when silent).
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
            child: FarmTapAnimationView(animation: widget.animation, size: context.sizes.animationLg),
          ),
          context.space.gapXl,
          Semantics(
            liveRegion: true,
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: context.text.headlineMedium?.copyWith(fontWeight: FarmTapWeights.bold),
            ),
          ),
          if (widget.message != null) ...[
            context.space.gapSm,
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: context.text.titleMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
          context.space.gapXl,
          AnimatedOpacity(
            opacity: _buttons ? 1 : 0,
            duration: context.motion.normal,
            child: IgnorePointer(
              ignoring: !_buttons,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => _finish(CelebrationAction.primary),
                    icon: widget.primaryIcon == null ? null : Icon(widget.primaryIcon),
                    label: Text(widget.primaryLabel),
                  ),
                  if (widget.secondaryLabel != null)
                    TextButton(
                      onPressed: () => _finish(CelebrationAction.secondary),
                      child: Text(widget.secondaryLabel!),
                    ),
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
        child: Center(child: SingleChildScrollView(child: body)),
      ),
    );
  }
}
