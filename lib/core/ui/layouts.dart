// Page layouts that don't use the navigation shell (rebuild prompt 4.1).
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/adaptive_scaffold.dart';
import 'package:farm_tap/core/ui/animation_view.dart';
import 'package:flutter/material.dart';

/// Auth and onboarding. Wide (tablet/desktop): a primary brand panel (40% /
/// 42%) with the logo box, a square illustration and the tagline; on the
/// right a 460 column, 56 from the top (or vertically centred with
/// [centerContent]). Phones: full-screen form, padding 24, [bottom] pinned.
class SplitAuthLayout extends StatelessWidget {
  const new({
    required this.child,
    required this.animation,
    required this.tagline,
    required this.description,
    super.key,
    this.header,
    this.bottom,
    this.centerContent = false,
    this.compactBottomPadding,
  });

  /// The form / content.
  final Widget child;

  /// Above the content on every width (back arrow, StepHeader).
  final Widget? header;

  /// Primary actions: pinned at the bottom on phones, under the content wider.
  final Widget? bottom;
  final FarmTapAnimation animation;
  final String tagline;
  final String description;

  /// Centre the right column vertically on wide screens (A02).
  final bool centerContent;

  /// Space under [bottom] on phones (default 24); smaller when [bottom] ends
  /// in a row of 48 dp links (A02 footer).
  final double? compactBottomPadding;

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
                  padding: EdgeInsets.fromLTRB(context.space.xl, context.space.lg, context.space.xl, context.space.xl),
                  child: child,
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.space.xl,
                    0,
                    context.space.xl,
                    compactBottomPadding ?? context.space.xl,
                  ),
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
    final column = SizedBox(
      width: context.sizes.authColumnWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ?header,
          child,
          if (bottom != null) ...[context.space.gapXl, bottom!],
        ],
      ),
    );
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
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: centerContent ? context.space.xxl : context.space.authTop,
                    bottom: context.space.xxl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: centerContent ? constraints.maxHeight - context.space.xxl * 2 : 0,
                    ),
                    child: Align(alignment: centerContent ? Alignment.center : Alignment.topCenter, child: column),
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

/// Where a dialog sits on a split auth screen: centred over the content
/// column (right of the brand panel), as in the B03 mockups.
Alignment splitContentAlignment(BuildContext context) {
  final panel = switch (context.formFactor) {
    FormFactor.expanded => context.sizes.authPanelFractionWide,
    FormFactor.medium => context.sizes.authPanelFractionMedium,
    FormFactor.compact => 0.0,
  };
  // Centre of the remaining width, in Alignment units (-1 .. 1).
  return Alignment(panel, 0);
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
    final logoInset = context.sizes.brandPanelLogoInset;
    final inset = context.sizes.brandPanelInset;
    return ColoredBox(
      color: context.colors.primary,
      child: SafeArea(
        right: false,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(logoInset, logoInset, logoInset, 0),
                child: Row(
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
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(inset, context.space.xxl + context.space.xs, inset, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.primaryContainer,
                          borderRadius: context.radii.dialog,
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.bottomCenter,
                        child: LayoutBuilder(
                          builder: (context, c) => FarmTapAnimationView(animation: animation, size: c.maxWidth),
                        ),
                      ),
                    ),
                    context.space.gapXl,
                    Text(tagline, style: context.text.headlineSmall?.copyWith(color: on)),
                    context.space.gapMd,
                    Text(description, style: context.text.bodyMedium?.copyWith(color: on)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centred screens (splash, check email, waitlist done, trial started, staff
/// tap card, PIN): content max 480, vertically centred, [bottom] pinned 24
/// from the bottom on phones (32 wider) — measured from A01 / A06.
class CenteredLayout extends StatelessWidget {
  const new({required this.child, super.key, this.bottom, this.top});

  final Widget child;

  /// Pinned at the top (back arrow, language switch).
  final Widget? top;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    // Content is centred on the whole screen (not the space above [bottom]),
    // as in the A01 / A06 mockups; [bottom] is pinned over it.
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
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
            if (top != null) Align(alignment: Alignment.topCenter, child: top),
            if (bottom != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.space.xl,
                    context.space.lg,
                    context.space.xl,
                    compact ? context.space.xl : context.space.xxl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: context.sizes.centeredMaxWidth),
                    child: bottom,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
