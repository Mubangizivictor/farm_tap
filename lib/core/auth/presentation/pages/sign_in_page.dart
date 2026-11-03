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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A02 — sign in. Google and email everywhere; Apple on iOS (and in the
/// mockups' web view). No phone-number sign-in.
///
/// Brand-only design (not farm-specific, decision: Victor 3 Nov 2026): the
/// slowly spinning FarmTap mark, the wordmark and a two-line promise, three
/// small feature cards, then the sign-in buttons. One centred column on every
/// width.
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
    return _SignInLayout(buttons: buttons);
  }
}

/// Brand block centred in the space above, feature cards and buttons below;
/// scrolls on short screens. Max width = the auth column on wide screens.
class _SignInLayout extends StatelessWidget {
  const new({required this.buttons});

  final Widget buttons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SpinningMark(),
        context.space.gapLg,
        Image.asset(
          FarmTapAssets.byBrightness(context, FarmTapAssets.wordmarkLight, FarmTapAssets.wordmarkDark),
          height: context.sizes.signInWordmarkHeight,
          fit: BoxFit.contain,
          semanticLabel: l10n.appName,
        ),
        context.space.gapMd,
        Text(
          l10n.signInTagline,
          textAlign: TextAlign.center,
          style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ],
    );
    final cards = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _FeatureCard(icon: Symbols.cloud_off_rounded, label: l10n.signInCardOffline),
        ),
        context.space.gapMd,
        Expanded(
          child: _FeatureCard(icon: Symbols.contactless_rounded, label: l10n.signInCardTap, tone: FarmTapTone.gold),
        ),
        context.space.gapMd,
        Expanded(
          child: _FeatureCard(icon: Symbols.verified_user_rounded, label: l10n.signInCardBackup),
        ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(context.space.xl, 0, context.space.xl, context.space.sm),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - context.space.sm),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: context.sizes.authColumnWidth),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: context.space.xxl),
                            child: Center(child: brand),
                          ),
                        ),
                        IntrinsicHeight(child: cards),
                        context.space.gapXxl,
                        buttons,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The FarmTap mark turning slowly on a soft glow. Still when the phone asks
/// for reduced motion.
class _SpinningMark extends StatefulWidget {
  const new();

  @override
  State<_SpinningMark> createState() => _SpinningMarkState();
}

class _SpinningMarkState extends State<_SpinningMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // One turn every 12 s: alive, but calm enough to read beside.
    _c.duration = context.motion.slow * 30;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _c
        ..stop()
        ..value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mark = context.sizes.signInMark;
    return ExcludeSemantics(
      child: Container(
        width: context.sizes.signInHalo,
        height: context.sizes.signInHalo,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [context.colors.primaryContainer, context.colors.surface]),
        ),
        child: RotationTransition(
          turns: _c,
          child: SvgPicture.asset(
            FarmTapAssets.byBrightness(context, FarmTapAssets.logoMarkLightSvg, FarmTapAssets.logoMarkDarkSvg),
            width: mark,
            height: mark,
          ),
        ),
      ),
    );
  }
}

/// One of the three small cards between the brand and the buttons.
class _FeatureCard extends StatelessWidget {
  const new({required this.icon, required this.label, this.tone = FarmTapTone.primary});

  final IconData icon;
  final String label;
  final FarmTapTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = tone.of(context);
    return Container(
      constraints: BoxConstraints(minHeight: context.sizes.signInFeatureCard),
      padding: EdgeInsets.symmetric(horizontal: context.space.sm, vertical: context.space.md),
      decoration: BoxDecoration(color: colors.container, borderRadius: context.radii.card),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, fill: 1, size: context.sizes.iconLg, color: colors.onContainer),
          context.space.gapXs,
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.text.labelMedium?.copyWith(color: colors.onContainer),
          ),
        ],
      ),
    );
  }
}
