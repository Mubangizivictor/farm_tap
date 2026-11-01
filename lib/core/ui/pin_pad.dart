import 'dart:async';
import 'dart:math' as math;

import 'package:farm_tap/core/sound/sound_service.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/big_number_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Row of PIN dots. Bump [errorTick] to shake them (300 ms) and vibrate
/// twice, as for a wrong PIN (UX_SPEC section 5).
class PinDots extends StatefulWidget {
  const new({required this.filled, super.key, this.length = 4, this.errorTick = 0});

  final int filled;
  final int length;
  final int errorTick;

  @override
  State<PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<PinDots> with SingleTickerProviderStateMixin {
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(PinDots old) {
    super.didUpdateWidget(old);
    if (widget.errorTick != old.errorTick) {
      _shake.duration = context.motion.shake;
      _shake.forward(from: 0);
      unawaited(SoundService.instance.play(FarmTapSound.error));
      unawaited(HapticFeedback.heavyImpact());
      unawaited(Future<void>.delayed(context.motion.fast, HapticFeedback.heavyImpact));
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, _) {
        final failed = _shake.isAnimating;
        final fill = failed ? context.status.danger : context.colors.primary;
        // Three full swings over the shake duration, fading out.
        final t = _shake.value;
        final dx = context.sizes.shakeDistance * (1 - t) * math.sin(t * 6 * math.pi);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.length; i++)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.space.md),
                  child: AnimatedContainer(
                    duration: context.motion.fast,
                    width: context.sizes.pinDot,
                    height: context.sizes.pinDot,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < widget.filled ? fill : Colors.transparent,
                      border: Border.all(
                        color: i < widget.filled || failed ? fill : context.colors.outline,
                        width: context.sizes.borderThick,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// PIN entry: dots + pill keypad. Calls [onCompleted] when [length] digits
/// are typed; return false for a wrong PIN and the dots shake and clear.
class PinPad extends StatefulWidget {
  const new({required this.onCompleted, super.key, this.length = 4, this.header, this.footer});

  final int length;
  final Future<bool> Function(String pin) onCompleted;
  final Widget? header;
  final Widget? footer;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  int _errors = 0;
  bool _busy = false;

  Future<void> _add(String d) async {
    if (_busy || _pin.length >= widget.length) return;
    setState(() => _pin += d);
    if (_pin.length == widget.length) {
      _busy = true;
      final ok = await widget.onCompleted(_pin);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (!ok) {
          _errors++;
          _pin = '';
        }
      });
    }
  }

  void _back() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.header != null) widget.header!,
        PinDots(filled: _pin.length, length: widget.length, errorTick: _errors),
        context.space.gapXl,
        BigNumberKeypad(onDigit: _add, onBackspace: _back, pill: true),
        if (widget.footer != null) widget.footer!,
      ],
    );
  }
}
