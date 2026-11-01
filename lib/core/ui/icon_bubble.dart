import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/tone.dart';
import 'package:flutter/material.dart';

/// Icon in a soft coloured circle (metric cards, actions, dialogs, lists).
class IconBubble extends StatelessWidget {
  const new({required this.icon, super.key, this.tone = FarmTapTone.success, this.size, this.iconSize});

  final IconData icon;
  final FarmTapTone tone;

  /// Defaults to `context.sizes.avatarMd`.
  final double? size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = tone.of(context);
    final dimension = size ?? context.sizes.avatarMd;
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(color: colors.container, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: ExcludeSemantics(
        child: Icon(icon, color: colors.onContainer, size: iconSize ?? context.sizes.iconMd),
      ),
    );
  }
}
