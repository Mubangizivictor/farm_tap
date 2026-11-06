import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';

/// A01 — the native splash brought to life. The logo starts exactly where
/// the native one was and keeps animating; it lifts a little while the
/// FarmTap name and tagline rise in right under it. Stays while start-up
/// work ([ready]) finishes (at least [FarmTapMotion.splash]), then calls
/// [onDone].
class SplashPage extends StatefulWidget {
  const new({super.key, this.onDone, this.ready});

  final VoidCallback? onDone;
  final Future<void>? ready;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this);
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _intro.duration = context.motion.slow;
    if (still) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
    unawaited(_run(context.motion.splash));
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  Timer? _minTimer;

  /// Moves on once both the shortest show time has passed and start-up is
  /// done. A Timer (not Future.delayed) so leaving early cancels it.
  Future<void> _run(Duration min) async {
    final shown = Completer<void>();
    _minTimer = Timer(min, shown.complete);
    try {
      await Future.wait([shown.future, widget.ready ?? Future<void>.value()]);
    } on Object {
      // Start-up trouble is shown later by the page that needs the data.
    }
    if (mounted) widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mark = context.sizes.splashMark;
    final word = context.sizes.splashWordmarkHeight;
    final gap = context.space.lg;
    final tagline = Text(
      l10n.splashTagline,
      textAlign: TextAlign.center,
      style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
    );
    final line = context.space.xxl;
    // Mark, name and tagline end up centred together; at the start the
    // whole group sits lower so the mark is exactly where the native one was.
    final group = mark + gap + word + context.space.sm + line;
    final lift = group / 2 - mark / 2;
    final curve = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: curve,
          builder: (context, _) {
            final t = curve.value;
            return Transform.translate(
              offset: Offset(0, lift * (1 - t)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FarmTapLoader(size: mark, semanticLabel: l10n.appName),
                  SizedBox(height: gap),
                  Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, gap * (1 - t)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            FarmTapAssets.byBrightness(
                              context,
                              FarmTapAssets.wordmarkLight,
                              FarmTapAssets.wordmarkDark,
                            ),
                            height: word,
                            excludeFromSemantics: true,
                          ),
                          SizedBox(height: context.space.sm),
                          SizedBox(height: line, child: tagline),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
