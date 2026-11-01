import 'dart:async';

import 'package:farm_tap/core/sound/sound_service.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Saved / synced / offline messages: 64 tall, radius 14, inverseSurface,
/// filled icon 24, bodyMedium, action labelLarge in inversePrimary. 3 s
/// (Undo 5 s on deliveries). Phones: 16 from the sides, just above the
/// bottom bar. Wide: 420 wide, bottom-right, 32 margin.
abstract final class FarmTapToast {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    IconData icon = Symbols.check_circle_rounded,
    FarmTapTone tone = FarmTapTone.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    bool playSound = true,
  }) {
    if (playSound && tone == FarmTapTone.success) {
      unawaited(SoundService.instance.play(FarmTapSound.success));
    }
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final width = MediaQuery.sizeOf(context).width;
    final wide = !context.isCompact;
    return messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration ?? context.motion.snackBar,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: wide
            ? EdgeInsets.only(
                left: width - context.sizes.toastWidth - context.space.xxl,
                right: context.space.xxl,
                bottom: context.space.xxl,
              )
            : EdgeInsets.fromLTRB(context.space.lg, 0, context.space.lg, context.space.lg),
        content: ToastContent(message: message, icon: icon, tone: tone, actionLabel: actionLabel, onAction: onAction),
      ),
    );
  }
}

/// The toast body. Public so goldens can show the toast state directly.
class ToastContent extends StatelessWidget {
  const new({
    required this.message,
    super.key,
    this.icon = Symbols.check_circle_rounded,
    this.tone = FarmTapTone.success,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final FarmTapTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  // The toast sits on the inverse surface, so use the inverse-friendly shade.
  Color _accent(BuildContext context) => switch (tone) {
    FarmTapTone.success || FarmTapTone.primary => context.colors.inversePrimary,
    FarmTapTone.warning || FarmTapTone.gold => context.colors.secondary,
    FarmTapTone.danger => context.colors.errorContainer,
    _ => context.colors.onInverseSurface,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.sizes.toastHeight,
      padding: EdgeInsets.symmetric(horizontal: context.space.lg),
      decoration: BoxDecoration(color: context.colors.inverseSurface, borderRadius: context.radii.snackBar),
      child: Row(
        children: [
          Icon(icon, fill: 1, color: _accent(context), size: context.sizes.iconMd),
          context.space.gapMd,
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(color: context.colors.onInverseSurface),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: context.text.labelLarge?.copyWith(color: context.colors.inversePrimary)),
            ),
        ],
      ),
    );
  }
}
