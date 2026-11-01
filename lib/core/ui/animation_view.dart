// Plays a FarmTap character animation (transparent WebP matching the theme).
// With "reduce motion" on (MediaQuery.disableAnimations) it shows the first
// frame as a still image instead. UX_SPEC section 5.
import 'dart:ui' as ui;

import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FarmTapAnimationView extends StatefulWidget {
  const new({required this.animation, super.key, this.size, this.semanticLabel});

  final FarmTapAnimation animation;

  /// Defaults to `context.sizes.animationMd`. Keep within 120-260 dp.
  final double? size;
  final String? semanticLabel;

  @override
  State<FarmTapAnimationView> createState() => _FarmTapAnimationViewState();
}

class _FarmTapAnimationViewState extends State<FarmTapAnimationView> {
  ui.Image? _still;
  String? _stillPath;

  Future<void> _loadStill(String path) async {
    _stillPath = path;
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    if (!mounted || _stillPath != path) return;
    setState(() => _still = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.animation.of(context);
    final size = widget.size ?? context.sizes.animationMd;
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_stillPath != path) {
        _still = null;
        _loadStill(path);
      }
      final still = _still;
      return Semantics(
        label: widget.semanticLabel,
        image: true,
        child: SizedBox.square(
          dimension: size,
          child: still == null ? null : RawImage(image: still, fit: BoxFit.contain),
        ),
      );
    }
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      ),
    );
  }
}
