import 'package:farm_tap/core/auth/domain/auth_repository.dart';
import 'package:farm_tap/core/auth/domain/entities/account_user.dart';
import 'package:farm_tap/core/auth/presentation/auth_error_text.dart';
import 'package:farm_tap/core/auth/presentation/cubit/auth_action_cubit.dart';
import 'package:farm_tap/core/auth/presentation/widgets/auth_widgets.dart';
import 'package:farm_tap/core/error/result.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A02 — sign in. Google and email everywhere; Apple on iOS (and in the
/// mockups' web view). No phone-number sign-in.
class SignInPage extends StatelessWidget {
  const new({required this.auth, required this.onSignedIn, required this.onEmail, super.key, this.showApple});

  final AuthRepository auth;
  final VoidCallback onSignedIn;
  final VoidCallback onEmail;

  /// Defaults to iOS / macOS / web.
  final bool? showApple;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthActionCubit(),
      child: _SignInView(auth: auth, onSignedIn: onSignedIn, onEmail: onEmail, showApple: showApple),
    );
  }
}

class _SignInView extends StatefulWidget {
  const new({required this.auth, required this.onSignedIn, required this.onEmail, this.showApple});

  final AuthRepository auth;
  final VoidCallback onSignedIn;
  final VoidCallback onEmail;
  final bool? showApple;

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  /// The provider being signed in with (its button shows the loader).
  SignInProvider? _working;

  Future<void> _provider(SignInProvider p, Future<Result<AccountUser>> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _working = p);
    final result = await context.read<AuthActionCubit>().run(action);
    if (!mounted) return;
    setState(() => _working = null);
    if (result == null) return;
    if (result.isSuccess) {
      widget.onSignedIn();
    } else {
      final message = authErrorText(l10n, result.failure);
      if (message == null) return;
      FarmTapToast.show(context, message: message, icon: Symbols.error_rounded, tone: FarmTapTone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apple =
        widget.showApple ??
        (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);
    final busy = context.watch<AuthActionCubit>().state.busy;
    final buttons = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FarmTapButton(
          label: l10n.continueGoogle,
          kind: ButtonKind.neutral,
          leading: const ProviderLogo(SignInProvider.google),
          loading: _working == SignInProvider.google,
          onPressed: busy ? null : () => _provider(SignInProvider.google, widget.auth.signInWithGoogle),
        ),
        if (apple) ...[
          SizedBox(height: context.space.keyGap),
          FarmTapButton(
            label: l10n.continueApple,
            kind: ButtonKind.neutral,
            leading: const ProviderLogo(SignInProvider.apple),
            loading: _working == SignInProvider.apple,
            onPressed: busy ? null : () => _provider(SignInProvider.apple, widget.auth.signInWithApple),
          ),
        ],
        const OrDivider(),
        FarmTapButton(label: l10n.continueEmail, icon: Symbols.mail_rounded, onPressed: busy ? null : widget.onEmail),
        const AuthFooter(),
      ],
    );
    Widget point(IconData icon, FarmTapTone tone, String text) => Padding(
      padding: EdgeInsets.only(bottom: context.space.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBubble(icon: icon, tone: tone, size: context.sizes.bubbleMd),
          context.space.gapMd,
          Flexible(child: Text(text, style: context.text.titleSmall)),
        ],
      ),
    );
    return SplitAuthLayout(
      animation: FarmTapAnimations.welcome,
      tagline: l10n.brandTagline,
      description: l10n.brandBody,
      bottom: buttons,
      // The footer links are 48 dp tall; keep the text where the mockup has it.
      compactBottomPadding: context.space.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: FarmTapLogo(height: context.sizes.appBarLogoHeight)),
          context.space.gapLg,
          Center(
            child: FarmTapAnimationView(animation: FarmTapAnimations.welcome, size: context.sizes.authIllustration),
          ),
          context.space.gapLg,
          AuthHeading(title: l10n.welcomeTitle, subtitle: l10n.welcomeBody, center: true),
          context.space.gapLg,
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                point(Symbols.cloud_off_rounded, FarmTapTone.primary, l10n.signInPointOffline),
                point(Symbols.contactless_rounded, FarmTapTone.gold, l10n.signInPointCards),
                point(Symbols.monitoring_rounded, FarmTapTone.info, l10n.signInPointAll),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
