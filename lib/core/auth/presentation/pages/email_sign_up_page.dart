import 'dart:async';

import 'package:farm_tap/core/auth/domain/auth_repository.dart';
import 'package:farm_tap/core/auth/domain/password_strength.dart';
import 'package:farm_tap/core/auth/presentation/auth_error_text.dart';
import 'package:farm_tap/core/auth/presentation/cubit/auth_action_cubit.dart';
import 'package:farm_tap/core/auth/presentation/widgets/auth_widgets.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A04 — create an account. Inline validation when a field loses focus.
/// After sign-up a verification email is sent (A06) and the user can carry
/// on with onboarding.
class EmailSignUpPage extends StatefulWidget {
  const new({required this.auth, required this.onCreated, super.key});

  final AuthRepository auth;

  /// Called with the email the verification link went to.
  final ValueChanged<String> onCreated;

  @override
  State<EmailSignUpPage> createState() => _EmailSignUpPageState();
}

class _EmailSignUpPageState extends State<EmailSignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  String? _suggested;
  final _cubit = AuthActionCubit();
  bool _agreed = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _agreeError;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && _name.text.isNotEmpty) _validateName();
    });
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && _email.text.isNotEmpty) _validateEmail();
    });
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus && _password.text.isNotEmpty) _validatePassword();
    });
    _confirmFocus.addListener(() {
      if (!_confirmFocus.hasFocus && _confirm.text.isNotEmpty) _validateConfirm();
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    for (final f in [_nameFocus, _emailFocus, _passwordFocus, _confirmFocus]) {
      f.dispose();
    }
    unawaited(_cubit.close());
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  bool _validateName() {
    setState(() => _nameError = _name.text.trim().isEmpty ? _l10n.nameRequired : null);
    return _nameError == null;
  }

  bool _validateEmail() {
    setState(() => _emailError = looksLikeEmail(_email.text) ? null : _l10n.emailIncomplete);
    return _emailError == null;
  }

  bool _validatePassword() {
    final p = _password.text;
    setState(
      () => _passwordError = p.length < PasswordRules.minLength
          ? _l10n.passwordTooShort
          : PasswordRules.meetsRules(p)
          ? null
          : _l10n.passwordWeak,
    );
    return _passwordError == null;
  }

  bool _validateConfirm() {
    setState(() => _confirmError = _confirm.text == _password.text ? null : _l10n.passwordsDontMatch);
    return _confirmError == null;
  }

  void _suggest() {
    final p = PasswordRules.suggest();
    _password.text = p;
    _confirm.text = p;
    setState(() {
      _suggested = p;
      _passwordError = null;
      _confirmError = null;
    });
  }

  Future<void> _submit() async {
    final ok = [_validateName(), _validateEmail(), _validatePassword(), _validateConfirm()].every((v) => v);
    setState(() => _agreeError = _agreed ? null : _l10n.agreeTermsRequired);
    if (!ok || !_agreed) return;
    final email = _email.text.trim();
    final result = await _cubit.run(
      () => widget.auth.signUpWithEmail(name: _name.text.trim(), email: email, password: _password.text),
    );
    if (!mounted || result == null) return;
    if (result.isSuccess) {
      await widget.auth.sendEmailVerification();
      widget.onCreated(email);
    } else {
      final f = result.failure;
      final message = authErrorText(_l10n, f) ?? _l10n.somethingWentWrongShort;
      setState(() {
        if (f?.message == 'weak-password') {
          _passwordError = message;
        } else {
          _emailError = message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return BlocBuilder<AuthActionCubit, AuthActionState>(
      bloc: _cubit,
      builder: (context, state) => SplitAuthLayout(
        animation: FarmTapAnimations.welcome,
        tagline: l10n.brandTagline,
        description: l10n.brandBody,
        header: const AuthBackButton(),
        bottom: FarmTapButton(label: l10n.createAccount, onPressed: state.busy ? null : _submit, loading: state.busy),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeading(title: l10n.signUpTitle, subtitle: l10n.signUpSubtitle),
            context.space.gapLg,
            FarmTapTextField(
              label: l10n.fullNameLabel,
              icon: Symbols.person_rounded,
              controller: _name,
              focusNode: _nameFocus,
              error: _nameError,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onSubmitted: (_) => _emailFocus.requestFocus(),
            ),
            context.space.gapLg,
            FarmTapTextField(
              label: l10n.emailLabel,
              icon: Symbols.mail_rounded,
              controller: _email,
              focusNode: _emailFocus,
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
              helper: l10n.passwordRuleStrong,
              password: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {
                _suggested = null;
                if (_passwordError != null) _passwordError = null;
              }),
              onSubmitted: (_) => _confirmFocus.requestFocus(),
            ),
            if (_password.text.isNotEmpty) ...[
              context.space.gapSm,
              PasswordStrengthBar(strength: PasswordRules.strength(_password.text)),
            ],
            if (_suggested != null) ...[
              context.space.gapXs,
              SelectableText(l10n.suggestedPasswordNote(_suggested!), style: context.text.bodySmall),
            ],
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextAction(label: l10n.suggestPassword, icon: Symbols.auto_awesome_rounded, onPressed: _suggest),
            ),
            context.space.gapSm,
            FarmTapTextField(
              label: l10n.confirmPasswordLabel,
              icon: Symbols.key_rounded,
              controller: _confirm,
              focusNode: _confirmFocus,
              error: _confirmError,
              password: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) {
                if (_confirmError != null) setState(() => _confirmError = null);
              },
            ),
            context.space.gapLg,
            InkWell(
              onTap: () => setState(() {
                _agreed = !_agreed;
                if (_agreed) _agreeError = null;
              }),
              child: Row(
                children: [
                  // The whole row is the 48 dp target; the box lines up with the fields.
                  SizedBox.square(
                    dimension: context.sizes.iconMd,
                    // Material draws an 18 dp box; the spec box is 24.
                    child: Transform.scale(
                      scale: context.sizes.checkbox / context.sizes.materialCheckbox,
                      child: Checkbox(
                        value: _agreed,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (v) => setState(() {
                          _agreed = v ?? false;
                          if (_agreed) _agreeError = null;
                        }),
                      ),
                    ),
                  ),
                  context.space.gapMd,
                  Expanded(child: Text(l10n.agreeTerms, style: context.text.bodyMedium)),
                ],
              ),
            ),
            if (_agreeError != null)
              Text(_agreeError!, style: context.text.bodySmall?.copyWith(color: context.colors.error)),
          ],
        ),
      ),
    );
  }
}
