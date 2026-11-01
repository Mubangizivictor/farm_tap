// Page layouts that don't use the navigation shell (rebuild prompt 4.1).
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/adaptive_scaffold.dart';
import 'package:farm_tap/core/ui/animation_view.dart';
import 'package:flutter/material.dart';

/// Auth and onboarding. Wide (tablet/desktop): a primary brand panel (40% /
/// 42%) with logo, illustration and tagline, and a 460 content column 56
/// from the top on the right. Phones: full-screen form, padding 24, [bottom]
/// pinned at the bottom.
class SplitAuthLayout extends StatelessWidget {
  const new({
    required this.child,
    required this.animation,
    required this.tagline,
    required this.description,
    super.key,
    this.header,
    this.bottom,
  });

  /// The form / content.
  final Widget child;

  /// Above the content on every width (e.g. StepHeader).
  final Widget? header;

  /// Primary actions: pinned at the bottom on phones, under the content wider.
  final Widget? bottom;
  final FarmTapAnimation animation;
  final String tagline;
  final String description;

  @override
  Widget build(BuildContext context) {
    final form = context.formFactor;
    if (form == FormFactor.compact) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.space.sm),
                  child: header,
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(context.space.xl, context.space.sm, context.space.xl, context.space.xl),
                  child: child,
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(context.space.xl, 0, context.space.xl, context.space.xl),
                  child: bottom,
                ),
            ],
          ),
        ),
      );
    }
    final fraction = form == FormFactor.expanded
        ? context.sizes.authPanelFractionWide
        : context.sizes.authPanelFractionMedium;
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: width * fraction,
            child: _BrandPanel(animation: animation, tagline: tagline, description: description),
          ),
          Expanded(
            child: SafeArea(
              left: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: context.space.authTop, bottom: context.space.xxl),
                child: Center(
                  child: SizedBox(
                    width: context.sizes.authColumnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ?header,
                        child,
                        if (bottom != null) ...[context.space.gapXl, bottom!],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const new({required this.animation, required this.tagline, required this.description});

  final FarmTapAnimation animation;
  final String tagline;
  final String description;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final on = context.colors.onPrimary;
    return ColoredBox(
      color: context.colors.primary,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: EdgeInsets.all(context.space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: context.sizes.logoBox,
                    height: context.sizes.logoBox,
                    padding: EdgeInsets.all(context.space.sm),
                    decoration: BoxDecoration(color: on, borderRadius: context.radii.banner),
                    child: const FarmTapLogoMark(),
                  ),
                  context.space.gapMd,
                  Text(l10n.appName, style: context.text.headlineSmall?.copyWith(color: on)),
                ],
              ),
              context.space.gapXl,
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: context.colors.primaryContainer, borderRadius: context.radii.dialog),
                  alignment: Alignment.center,
                  child: LayoutBuilder(
                    builder: (context, c) => FarmTapAnimationView(
                      animation: animation,
                      size: c.biggest.shortestSide * context.sizes.illustrationFill,
                    ),
                  ),
                ),
              ),
              context.space.gapXl,
              Text(tagline, style: context.text.headlineSmall?.copyWith(color: on)),
              context.space.gapSm,
              Text(description, style: context.text.bodyMedium?.copyWith(color: on)),
              context.space.gapXl,
            ],
          ),
        ),
      ),
    );
  }
}

/// Centred screens (splash, check email, waitlist done, trial started, staff
/// tap card, PIN): content max 480, vertically centred, [bottom] pinned 48
/// from the bottom on phones (32 wider).
class CenteredLayout extends StatelessWidget {
  const new({required this.child, super.key, this.bottom, this.top});

  final Widget child;

  /// Pinned at the top (back arrow, language switch).
  final Widget? top;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ?top,
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: context.space.xl),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: context.sizes.centeredMaxWidth),
                    child: child,
                  ),
                ),
              ),
            ),
            if (bottom != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.space.xl,
                  context.space.lg,
                  context.space.xl,
                  compact ? context.space.xxxl : context.space.xxl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: context.sizes.centeredMaxWidth),
                  child: bottom,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
