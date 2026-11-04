import 'package:farm_tap/core/auth/presentation/widgets/auth_widgets.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Total onboarding steps shown in "Step x of 6".
const onboardingSteps = 6;

/// One onboarding step (B02, B05-B09): step header with back (and optional
/// Skip), title + subtitle, content, and the action pinned at the bottom on
/// phones. Wide screens use the brand panel with [animation].
class OnboardingStep extends StatelessWidget {
  const new({
    required this.step,
    required this.title,
    required this.animation,
    required this.child,
    super.key,
    this.subtitle,
    this.action,
    this.onContinue,
    this.onSkip,
  });

  final int step;
  final String title;
  final String? subtitle;
  final FarmTapAnimation animation;
  final Widget child;

  /// Custom bottom action; defaults to "Continue →" calling [onContinue].
  final Widget? action;
  final VoidCallback? onContinue;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SplitAuthLayout(
      animation: animation,
      tagline: l10n.brandTagline,
      description: l10n.brandBody,
      header: StepHeader(
        step: step,
        total: onboardingSteps,
        onBack: () => popOrGo(context, RouteInfo.maybeOf(context)?.parent),
        onSkip: onSkip,
      ),
      bottom:
          action ??
          FarmTapButton(label: l10n.continueLabel, trailingIcon: Symbols.arrow_forward_rounded, onPressed: onContinue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeading(title: title, subtitle: subtitle),
          context.space.gapLg,
          child,
        ],
      ),
    );
  }
}
