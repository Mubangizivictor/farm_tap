// Animation timing tokens. Use: context.motion.normal, context.motion.standard
import 'package:flutter/material.dart';

@immutable
class FarmTapMotion extends ThemeExtension<FarmTapMotion> {
  const new({
    this.fast = const Duration(milliseconds: 150),
    this.normal = const Duration(milliseconds: 250),
    this.slow = const Duration(milliseconds: 400),
    this.splash = const Duration(milliseconds: 2000),
    this.snackBar = const Duration(seconds: 3),
    this.shake = const Duration(milliseconds: 300),
    this.celebration = const Duration(milliseconds: 1800),
    this.autoAdvance = const Duration(seconds: 2),
    this.undoWindow = const Duration(seconds: 5),
    this.standard = Curves.easeOutCubic,
    this.emphasized = Curves.easeOutBack,
    this.exit = Curves.easeInCubic,
  });

  final Duration fast;
  final Duration normal;
  final Duration slow;

  /// How long the animated splash plays before moving on.
  final Duration splash;

  /// How long confirmation messages stay on screen.
  final Duration snackBar;

  /// Wrong-PIN dots shake.
  final Duration shake;

  /// How long a celebration plays before its buttons appear.
  final Duration celebration;

  /// Milk / delivery flows move on by themselves after this long.
  final Duration autoAdvance;

  /// How long Undo stays available on a saved delivery.
  final Duration undoWindow;

  final Curve standard;
  final Curve emphasized;
  final Curve exit;

  @override
  FarmTapMotion copyWith({
    Duration? fast,
    Duration? normal,
    Duration? slow,
    Duration? splash,
    Duration? snackBar,
    Duration? shake,
    Duration? celebration,
    Duration? autoAdvance,
    Duration? undoWindow,
    Curve? standard,
    Curve? emphasized,
    Curve? exit,
  }) =>
      FarmTapMotion(
        fast: fast ?? this.fast,
        normal: normal ?? this.normal,
        slow: slow ?? this.slow,
        splash: splash ?? this.splash,
        snackBar: snackBar ?? this.snackBar,
        shake: shake ?? this.shake,
        celebration: celebration ?? this.celebration,
        autoAdvance: autoAdvance ?? this.autoAdvance,
        undoWindow: undoWindow ?? this.undoWindow,
        standard: standard ?? this.standard,
        emphasized: emphasized ?? this.emphasized,
        exit: exit ?? this.exit,
      );

  @override
  FarmTapMotion lerp(FarmTapMotion? other, double t) => t < 0.5 ? this : (other ?? this);
}
