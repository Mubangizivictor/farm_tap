import 'dart:async';

import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';

/// A01 — the native splash, brought to life: the same logo in the same
/// place, now animated, with the wordmark at the bottom. It stays while
/// start-up work ([ready]) finishes (at least [FarmTapMotion.splash]),
/// then calls [onDone].
class SplashPage extends StatefulWidget {
  const new({super.key, this.onDone, this.ready});

  final VoidCallback? onDone;
  final Future<void>? ready;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_run(context.motion.splash));
  }

  Future<void> _run(Duration min) async {
    try {
      await Future.wait([Future<void>.delayed(min), widget.ready ?? Future<void>.value()]);
    } on Object {
      // Start-up trouble is shown later by the page that needs the data.
    }
    if (mounted) widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: FarmTapLoader(size: context.sizes.splashMark, semanticLabel: 'FarmTap'),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            // Pinned to the screen's bottom edge, like the native splash.
            child: Image.asset(
              FarmTapAssets.byBrightness(context, FarmTapAssets.splashBrandingLight, FarmTapAssets.splashBrandingDark),
              width: context.sizes.splashBranding,
              excludeFromSemantics: true,
            ),
          ),
        ],
      ),
    );
  }
}
