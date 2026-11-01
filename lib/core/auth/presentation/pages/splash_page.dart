import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';

/// A01 — animated splash. Plays for up to 2 s while the local database opens,
/// then calls [onDone]. The native splash shows the logo before this.
class SplashPage extends StatefulWidget {
  const new({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer ??= Timer(context.motion.splash, () => widget.onDone?.call());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CenteredLayout(
      bottom: Text(
        l10n.splashLoading,
        textAlign: TextAlign.center,
        style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FarmTapAnimationView(animation: FarmTapAnimations.milking, size: context.sizes.splashAnimationWidth),
          context.space.gapXl,
          FarmTapLogo(height: context.sizes.authLogoHeight),
          context.space.gapXl,
          Text(
            l10n.splashTagline,
            textAlign: TextAlign.center,
            style: context.text.titleLarge?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
