import 'dart:async';

import 'package:farm_tap/core/auth/domain/auth_repository.dart';
import 'package:farm_tap/core/auth/presentation/cubit/auth_action_cubit.dart';
import 'package:farm_tap/core/auth/presentation/widgets/auth_widgets.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A05 — reset password. Always shows the same success toast, so it never
/// reveals whether the email has an account.
class ForgotPasswordPage extends StatefulWidget {
  const new({required this.auth, super.key, this.initialEmail});

  final AuthRepository auth;
  final String? initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _cubit = AuthActionCubit();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    setState(() => _error = looksLikeEmail(email) ? null : l10n.emailIncomplete);
    if (_error != null) return;
    await _cubit.run(() => widget.auth.sendPasswordReset(email));
    if (!mounted) return;
    FarmTapToast.show(
      context,
      message: l10n.resetLinkSent(email),
      icon: Symbols.mail_rounded,
      singleLine: true,
      abovePinnedButton: context.isCompact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AuthActionCubit, AuthActionState>(
      bloc: _cubit,
      builder: (context, state) => SplitAuthLayout(
        animation: FarmTapAnimations.welcome,
        tagline: l10n.brandTagline,
        description: l10n.brandBody,
        header: const AuthBackButton(),
        bottom: FarmTapButton(label: l10n.sendResetLink, onPressed: state.busy ? null : _send),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeading(title: l10n.resetTitle, subtitle: l10n.resetSubtitle),
            context.space.gapLg,
            FarmTapTextField(
              label: l10n.emailLabel,
              icon: Symbols.mail_rounded,
              controller: _email,
              error: _error,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _send(),
            ),
          ],
        ),
      ),
    );
  }
}
