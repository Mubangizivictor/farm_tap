import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/settings/app_settings_cubit.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/navigation_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// "G" / "A" letter in a small neutral circle: placeholder for the official
/// Google / Apple marks (TODO: official branding before release).
class ProviderBadge extends StatelessWidget {
  const new(this.letter, {super.key});

  final String letter;

  @override
  Widget build(BuildContext context) {
    final size = context.sizes.iconMd;
    // Decorative: the button label already names the provider.
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: context.colors.surfaceContainerHigh),
        child: Text(letter, style: context.text.labelSmall),
      ),
    );
  }
}

/// "English · Runyankore   Terms · Privacy" under the sign-in buttons.
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
        link(l10n.languageEnglish, () => context.read<AppSettingsCubit>().setLanguage('en')),
        dot,
        link(l10n.languageRunyankore, () => context.read<AppSettingsCubit>().setLanguage('nyn')),
        context.space.gapLg,
        link(l10n.terms, onTerms),
        dot,
        link(l10n.privacy, onPrivacy),
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
