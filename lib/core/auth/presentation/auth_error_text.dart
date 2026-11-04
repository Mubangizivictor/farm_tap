import 'package:farm_tap/core/error/failure.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';

/// What to tell the person when sign-in or sign-up fails; null when they
/// closed the Apple / Google sheet themselves.
String? authErrorText(AppLocalizations l10n, Failure? f) {
  final code = f?.message ?? '';
  return switch ((f, code)) {
    (_, 'cancelled') => null,
    (NetworkFailure(), _) => l10n.authNoInternet,
    (_, 'operation-not-allowed') => l10n.authProviderOff,
    (_, 'account-exists-with-different-credential') => l10n.authOtherMethod,
    (_, 'email-already-in-use') => l10n.authEmailInUse,
    (_, 'weak-password') => l10n.passwordWeak,
    _ => l10n.authFailedCode(code.isEmpty ? 'unknown' : code.split(RegExp(r'[\s:]')).first),
  };
}
