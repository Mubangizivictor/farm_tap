import 'package:farm_tap/core/auth/domain/password_strength.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

enum SignInProvider { google, apple }

/// The provider's own mark on its sign-in button: Google's "G", Apple's logo.
class ProviderLogo extends StatelessWidget {
  const new(this.provider, {super.key});

  final SignInProvider provider;

  @override
  Widget build(BuildContext context) {
    final size = context.sizes.iconMd;
    // Decorative: the button label already names the provider.
    return ExcludeSemantics(
      child: switch (provider) {
        SignInProvider.google => SvgPicture.asset(FarmTapAssets.googleG, width: size, height: size),
        SignInProvider.apple => Icon(Icons.apple, size: size, color: context.colors.onSurface),
      },
    );
  }
}

/// "—— or ——" between the provider buttons and email.
class OrDivider extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: context.colors.outlineVariant, height: context.sizes.borderThin),
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.space.sm),
      child: Row(
        children: [
          line,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.space.md),
            child: Text(
              AppLocalizations.of(context).orLabel,
              style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
          line,
        ],
      ),
    );
  }
}

/// "Terms · Privacy" under the sign-in buttons.
/// Tapping a language switches the app language at once.
class AuthFooter extends StatelessWidget {
  const new({super.key, this.onTerms, this.onPrivacy});

  final VoidCallback? onTerms;
  final VoidCallback? onPrivacy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = context.text.bodySmall;
    Widget link(String label, VoidCallback? onTap) => Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.sizes.touchTarget, minWidth: context.sizes.touchTarget),
          child: Align(widthFactor: 1, heightFactor: 1, child: Text(label, style: style)),
        ),
      ),
    );
    final dot = ExcludeSemantics(child: Text(' · ', style: style));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shown once the Terms and Privacy pages exist.
        if (onTerms != null) link(l10n.terms, onTerms),
        if (onTerms != null && onPrivacy != null) dot,
        if (onPrivacy != null) link(l10n.privacy, onPrivacy),
      ],
    );
  }
}

/// Screen title + subtitle at the top of an auth form (headlineSmall + bodyMedium).
class AuthHeading extends StatelessWidget {
  const new({required this.title, super.key, this.subtitle, this.center = false});

  final String title;
  final String? subtitle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, textAlign: align, style: context.text.headlineSmall),
        if (subtitle != null) ...[
          context.space.gapXs,
          Text(
            subtitle!,
            textAlign: align,
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// Back arrow row above a form (phone: in the header slot).
class AuthBackButton extends StatelessWidget {
  const new({super.key, this.onBack, this.fallback});

  final VoidCallback? onBack;

  /// Parent route when there is nothing to pop (deep link, web refresh).
  final String? fallback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: IconButton(
        tooltip: l10n.back,
        onPressed: onBack ?? () => popOrGo(context, fallback ?? RouteInfo.maybeOf(context)?.parent),
        icon: Icon(Symbols.arrow_back_rounded, size: context.sizes.iconLg),
      ),
    );
  }
}

/// Basic email check used for inline validation.
bool looksLikeEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(value.trim());

/// Thin bar + word under the sign-up password: Weak / Fair / Good / Strong.
class PasswordStrengthBar extends StatelessWidget {
  const new({required this.strength, super.key});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, tone) = switch (strength) {
      PasswordStrength.weak => (l10n.passwordStrengthWeak, FarmTapTone.danger),
      PasswordStrength.fair => (l10n.passwordStrengthFair, FarmTapTone.warning),
      PasswordStrength.good => (l10n.passwordStrengthGood, FarmTapTone.info),
      PasswordStrength.strong => (l10n.passwordStrengthStrong, FarmTapTone.success),
    };
    return FarmTapProgress(
      value: (strength.index + 1) / PasswordStrength.values.length,
      thin: true,
      trailingLabel: label,
      color: tone.of(context).accent,
    );
  }
}
