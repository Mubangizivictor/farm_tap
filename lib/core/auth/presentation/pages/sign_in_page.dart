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
/// Brand-only design (not farm-specific): a green brand panel with the logo
/// and a short promise, and the sign-in buttons on a sheet below it (phones)
/// or beside it (tablet and desktop).
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
    return _SignInHeroLayout(buttons: buttons);
  }
}

/// Phones: green brand panel filling the top, buttons on a rounded sheet
/// pinned to the bottom (scrolls on very short screens). Wider: brand panel
/// on the left, buttons centred in a column on the right.
class _SignInHeroLayout extends StatelessWidget {
  const new({required this.buttons});

  final Widget buttons;

  @override
  Widget build(BuildContext context) {
    final wordmark = Image.asset(
      FarmTapAssets.byBrightness(context, FarmTapAssets.wordmarkLight, FarmTapAssets.wordmarkDark),
      height: context.sizes.signInWordmarkHeight,
      fit: BoxFit.contain,
      semanticLabel: AppLocalizations.of(context).appName,
    );
    final panel = context.formFactor == FormFactor.compact;
    if (panel) {
      final sheet = DecoratedBox(
        decoration: BoxDecoration(color: context.colors.surface, borderRadius: context.radii.sheet),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.space.xl, context.space.xxl, context.space.xl, context.space.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: wordmark),
                context.space.gapXl,
                buttons,
              ],
            ),
          ),
        ),
      );
      return Scaffold(
        backgroundColor: context.status.authHero,
        body: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(child: _BrandHero(wide: false)),
                    sheet,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final fraction = context.formFactor == FormFactor.expanded
        ? context.sizes.authPanelFractionWide
        : context.sizes.authPanelFractionMedium;
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: MediaQuery.sizeOf(context).width * fraction, child: const _BrandHero(wide: true)),
          Expanded(
            child: SafeArea(
              left: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: context.space.xxl, horizontal: context.space.xl),
                  child: SizedBox(
                    width: context.sizes.authColumnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(child: wordmark),
                        context.space.gapXxl,
                        buttons,
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

/// Logo mark, "Your records, always with you." and one line of detail on the
/// brand green, with a faint oversized mark hanging off the top-right corner.
class _BrandHero extends StatelessWidget {
  const new({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final on = context.status.onAuthHero;
    final watermark = context.sizes.signInWatermark;
    final offset = context.sizes.signInWatermarkOffset;
    final inset = wide ? context.sizes.brandPanelInset : context.space.xxl;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The dark-mode mark (mint posts, gold sun) reads on the green in both themes.
        SvgPicture.asset(
          FarmTapAssets.logoMarkDarkSvg,
          width: wide ? context.sizes.signInHeroMarkWide : context.sizes.signInHeroMark,
          height: wide ? context.sizes.signInHeroMarkWide : context.sizes.signInHeroMark,
          excludeFromSemantics: true,
        ),
        context.space.gapXxl,
        Semantics(
          header: true,
          child: Text(l10n.signInHeroTitle, style: context.text.displaySmall?.copyWith(color: on)),
        ),
        context.space.gapLg,
        Text(l10n.signInHeroBody, style: context.text.bodyLarge?.copyWith(color: on)),
      ],
    );
    return ColoredBox(
      color: context.status.authHero,
      child: Stack(
        children: [
          Positioned(
            top: -offset,
            right: -offset,
            child: ExcludeSemantics(
              child: SvgPicture.asset(
                FarmTapAssets.logoMarkLightSvg,
                width: watermark,
                height: watermark,
                colorFilter: ColorFilter.mode(context.status.authHeroWatermark, BlendMode.srcIn),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            right: !wide,
            child: Padding(
              padding: EdgeInsets.fromLTRB(inset, wide ? 0 : context.space.xxxl, inset, context.space.xxxl),
              child: Align(
                alignment: wide ? AlignmentDirectional.centerStart : AlignmentDirectional.topStart,
                child: text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
