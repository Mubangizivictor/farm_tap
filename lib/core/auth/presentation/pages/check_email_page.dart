import 'package:farm_tap/core/auth/domain/auth_repository.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A06 — check your email. The user can carry on with setup before
/// verifying.
class CheckEmailPage extends StatelessWidget {
  const new({required this.auth, required this.email, required this.onContinue, super.key});

  final AuthRepository auth;
  final String email;
  final VoidCallback onContinue;

  Future<void> _resend(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await auth.sendEmailVerification();
    if (!context.mounted) return;
    FarmTapToast.show(context, message: l10n.emailSentAgain, icon: Symbols.mail_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CenteredLayout(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FarmTapButton(label: l10n.continueSetup, onPressed: onContinue),
          context.space.gapMd,
          TextAction(label: l10n.resendEmail, onPressed: () => _resend(context)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FarmTapAnimationView(animation: FarmTapAnimations.smsSent, size: context.sizes.animationCelebration),
          context.space.gapLg,
          Text(l10n.checkEmailTitle, textAlign: TextAlign.center, style: context.text.headlineSmall),
          context.space.gapSm,
          Text(
            l10n.checkEmailBody(email),
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
