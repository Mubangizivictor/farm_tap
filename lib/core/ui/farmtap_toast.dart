import 'dart:async';

import 'package:farm_tap/core/sound/sound_service.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';

/// Saved / synced / offline messages. Shows for 3 s, with one optional action
/// (Undo stays for 5 s on deliveries). Above the bottom bar on phones,
/// bottom-right on wide screens. UX_SPEC section 4.
abstract final class FarmTapToast {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle_rounded,
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
    final accent = tone == FarmTapTone.neutral ? context.colors.onInverseSurface : _toastAccent(context, tone);
    final wide = !context.isCompact;
    final width = MediaQuery.sizeOf(context).width;
    return messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration ?? context.motion.snackBar,
        margin: wide
            ? EdgeInsets.only(
                left: width - context.sizes.toastWidth - context.space.xl,
                right: context.space.xl,
                bottom: context.space.xl,
              )
            : null,
        content: Row(
          children: [
            Icon(icon, color: accent, size: context.sizes.iconLg),
            context.space.gapMd,
            Expanded(child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: context.colors.inversePrimary,
                onPressed: onAction ?? () {},
              ),
      ),
    );
  }

  // Toast sits on the dark inverse surface, so use the bright dark-mode shade.
  static Color _toastAccent(BuildContext context, FarmTapTone tone) => switch (tone) {
    FarmTapTone.success => context.colors.inversePrimary,
    FarmTapTone.warning => context.colors.secondary,
    FarmTapTone.danger => context.colors.errorContainer,
    _ => context.colors.onInverseSurface,
  };
}
