// The FarmTap mark as the app's loading animation: the ring of dots lights
// up in turn around the gold centre, which breathes. Used for every wait:
// page loads, sign-in, refresh and buttons that are working.
import 'dart:math' as math;

import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';

class FarmTapLoader extends StatefulWidget {
  const new({super.key, this.size, this.semanticLabel = 'Loading'});

  /// Defaults to 48 dp (iconXl-ish); buttons pass a smaller size.
  final double? size;
  final String semanticLabel;

  @override
  State<FarmTapLoader> createState() => _FarmTapLoaderState();
}

class _FarmTapLoaderState extends State<FarmTapLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _c.duration = context.motion.slow * 4;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _c
        ..stop()
        ..value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? context.sizes.avatarLg;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox.square(
        dimension: size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _MarkPainter(
              t: _c.value,
              still: still,
              dot: context.colors.primary,
              gold: context.status.brandGold,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const new({required this.t, required this.still, required this.dot, required this.gold});

  final double t;
  final bool still;
  final Color dot;
  final Color gold;

  // Geometry of logo_mark.svg (120 x 120).
  static const _dots = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 120;
    final c = Offset(size.width / 2, size.height / 2);
    final lead = t * _dots;
    for (var i = 0; i < _dots; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / _dots;
      // How far behind the travelling light this dot is (0 = lit).
      final behind = (lead - i) % _dots;
      final glow = still ? 1.0 : (1 - behind / _dots);
      final paint = Paint()..color = dot.withValues(alpha: 0.25 + 0.75 * glow * glow);
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * 44 * k, 5 * k * (0.8 + 0.2 * glow), paint);
    }
    final breathe = still ? 1.0 : 0.88 + 0.12 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
    canvas
      ..drawCircle(
        c,
        26 * k,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * k
          ..color = gold,
      )
      ..drawCircle(c, 13 * k * breathe, Paint()..color = gold);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t || old.still != still || old.dot != dot || old.gold != gold;
}

/// A whole page waiting for its data: the loader in the middle.
class FarmTapPageLoader extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: context.space.xxxl),
    child: const Center(child: FarmTapLoader()),
  );
}
