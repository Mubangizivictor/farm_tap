// A08 — staff sign-in on the worker's own phone (decision 0016 §5): phone
// number + 4-digit PIN. The first time (or after a manager reset) the
// worker must choose their own PIN before going on.
import 'dart:async';

import 'package:farm_tap/core/auth/domain/staff_login_repository.dart';
import 'package:farm_tap/core/auth/presentation/widgets/auth_widgets.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum _Step { phone, pin, newPin, confirm }

class StaffSignInPage extends StatefulWidget {
  const new({required this.repo, required this.onSignedIn, super.key});

  final StaffLoginRepository repo;

  /// Signed in (and the PIN chosen when needed). `newPin` is the PIN the
  /// worker just chose (`null` when no change was needed), so the farm phone's card unlock gets it too.
  final void Function(StaffSignIn signIn, String? newPin) onSignedIn;

  @override
  State<StaffSignInPage> createState() => _StaffSignInPageState();
}

class _StaffSignInPageState extends State<StaffSignInPage> {
  final _phone = TextEditingController();
  _Step _step = _Step.phone;
  String? _error;
  late StaffSignIn _signedIn;
  String _first = '';
  int _padKey = 0;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _toPin() {
    final l10n = AppLocalizations.of(context);
    if (ugPhoneDigits(_phone.text) == null) {
      setState(() => _error = l10n.staffPhoneInvalid);
      return;
    }
    setState(() {
      _error = null;
      _step = _Step.pin;
      _padKey++;
    });
  }

  Future<bool> _signIn(String pin) async {
    final l10n = AppLocalizations.of(context);
    final r = await widget.repo.signIn(phone: _phone.text, pin: pin);
    if (!mounted) return false;
    final data = r.data;
    if (data == null) {
      setState(
        () => _error = switch (r.failure?.message) {
          StaffLoginError.tooMany => l10n.staffSignInTooMany,
          StaffLoginError.offline => l10n.staffSignInOffline,
          _ => l10n.staffSignInWrong,
        },
      );
      return false;
    }
    if (!data.mustChangePin) {
      widget.onSignedIn(data, null);
      return true;
    }
    setState(() {
      _signedIn = data;
      _error = null;
      _step = _Step.newPin;
      _padKey++;
    });
    return true;
  }

  Future<bool> _newPin(String pin) async {
    final l10n = AppLocalizations.of(context);
    if (weakPin(pin)) {
      setState(() => _error = l10n.pinTooEasy);
      return false;
    }
    setState(() {
      _first = pin;
      _error = null;
      _step = _Step.confirm;
      _padKey++;
    });
    return true;
  }

  Future<bool> _confirm(String pin) async {
    final l10n = AppLocalizations.of(context);
    if (pin != _first) {
      setState(() {
        _error = l10n.pinsDoNotMatch;
        _step = _Step.newPin;
        _padKey++;
      });
      return false;
    }
    final r = await widget.repo.changePin(pin);
    if (!mounted) return false;
    if (r.isFailure) {
      setState(() => _error = l10n.staffSignInOffline);
      return false;
    }
    FarmTapToast.show(context, message: l10n.pinChangedToast);
    widget.onSignedIn(_signedIn, pin);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, subtitle) = switch (_step) {
      _Step.phone => (l10n.staffSignInTitle, l10n.staffSignInBody),
      _Step.pin => (l10n.enterPin, l10n.staffSignInPinBody(_phone.text)),
      _Step.newPin => (l10n.chooseOwnPinTitle, l10n.chooseOwnPinBody),
      _Step.confirm => (l10n.confirmPinTitle, l10n.confirmPinBody),
    };
    return SplitAuthLayout(
      animation: FarmTapAnimations.welcome,
      tagline: l10n.brandTagline,
      description: l10n.brandBody,
      header: const AuthBackButton(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeading(title: title, subtitle: subtitle),
          context.space.gapLg,
          if (_step == _Step.phone) ...[
            FarmTapTextField(
              label: l10n.phoneNumberLabel,
              icon: Symbols.call_rounded,
              prefixText: l10n.phonePrefix,
              controller: _phone,
              autofocus: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [UgPhoneFormatter()],
              error: _error,
              onSubmitted: (_) => _toPin(),
            ),
            context.space.gapLg,
            FarmTapButton(label: l10n.next, icon: Symbols.arrow_forward_rounded, large: true, onPressed: _toPin),
            context.space.gapLg,
            FarmTapBanner(
              tone: FarmTapTone.info,
              icon: Symbols.info_rounded,
              title: l10n.staffSignInHelpTitle,
              message: l10n.staffSignInHelpBody,
            ),
          ] else ...[
            if (_error != null) ...[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: context.colors.error),
              ),
              context.space.gapMd,
            ],
            Center(
              child: PinPad(
                key: ValueKey(_padKey),
                onCompleted: switch (_step) {
                  _Step.pin => _signIn,
                  _Step.newPin => _newPin,
                  _ => _confirm,
                },
              ),
            ),
            if (_step == _Step.pin)
              Center(
                child: TextAction(
                  label: l10n.changeNumber,
                  small: true,
                  onPressed: () => setState(() {
                    _step = _Step.phone;
                    _error = null;
                  }),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
