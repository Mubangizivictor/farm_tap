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

/// A03 — sign in with email. Keyboard "Next" moves to the password, "Done"
/// submits. Errors appear under the field, never as a popup.
class EmailSignInPage extends StatefulWidget {
  const new({
    required this.auth,
    required this.onSignedIn,
    required this.onForgotPassword,
    required this.onCreateAccount,
    super.key,
  });

  final AuthRepository auth;
  final VoidCallback onSignedIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onCreateAccount;

  @override
  State<EmailSignInPage> createState() => _EmailSignInPageState();
}

class _EmailSignInPageState extends State<EmailSignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  final _cubit = AuthActionCubit();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _emailError = looksLikeEmail(_email.text) ? null : l10n.emailIncomplete;
      _passwordError = null;
    });
    if (_emailError != null) return;
    final result = await _cubit.run(
      () => widget.auth.signInWithEmail(email: _email.text.trim(), password: _password.text),
    );
    if (!mounted || result == null) return;
    if (result.isSuccess) {
      widget.onSignedIn();
    } else {
      setState(() => _passwordError = l10n.signInFailed);
    }
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
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FarmTapButton(label: l10n.signIn, onPressed: state.busy ? null : _submit),
            context.space.gapXs,
            TextAction(label: l10n.newToFarmTap, onPressed: widget.onCreateAccount, dense: true),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeading(title: l10n.emailSignInTitle, subtitle: l10n.emailSignInSubtitle),
            context.space.gapLg,
            FarmTapTextField(
              label: l10n.emailLabel,
              icon: Symbols.mail_rounded,
              controller: _email,
              error: _emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            context.space.gapLg,
            FarmTapTextField(
              label: l10n.passwordLabel,
              icon: Symbols.key_rounded,
              controller: _password,
              focusNode: _passwordFocus,
              error: _passwordError,
              password: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextAction(label: l10n.forgotPassword, onPressed: widget.onForgotPassword),
            ),
          ],
        ),
      ),
    );
  }
}
