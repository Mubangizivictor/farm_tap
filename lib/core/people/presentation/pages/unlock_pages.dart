// Staff unlock on the farm phone: C01 tap card, C02 card number, C03/C04
// PIN (C04 = wrong-PIN state), C05 NFC turned off (dialog on C01).
import 'dart:async';

import 'package:farm_tap/core/auth/presentation/widgets/auth_widgets.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/nfc/card_reader.dart';
import 'package:farm_tap/core/nfc/card_tap_listener.dart';
import 'package:farm_tap/core/people/domain/staff_access_repository.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/people/presentation/widgets/choose_pin_sheet.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

/// C01 — tap your card. The NFC reader listens while this screen is open
/// (UI phase: a debug "Simulate tap" button instead). When NFC is off the
/// C05 dialog opens.
class TapCardPage extends StatefulWidget {
  const new({
    required this.farmName,
    required this.access,
    required this.onCard,
    required this.onTypeNumber,
    super.key,
    this.onOwnerSignIn,
    this.onSwitchFarm,
    this.showSimulate = false,
  });

  final String farmName;
  final StaffAccessRepository access;

  /// A card was read: its number.
  final ValueChanged<String> onCard;
  final VoidCallback onTypeNumber;
  final VoidCallback? onOwnerSignIn;
  final VoidCallback? onSwitchFarm;

  /// Debug builds only: pretend card 0142 was tapped.
  final bool showSimulate;

  @override
  State<TapCardPage> createState() => _TapCardPageState();
}

class _TapCardPageState extends State<TapCardPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_checkNfc());
  }

  Future<void> _checkNfc() async {
    if ((await widget.access.nfcAvailable() && await CardReader.instance.available()) || !mounted) return;
    await showNfcOffDialog(context, onTypeNumber: widget.onTypeNumber);
  }

  void _simulate() {
    unawaited(HapticFeedback.selectionClick());
    widget.onCard('0142');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CardTapListener(
      onCard: widget.onCard,
      prompt: l10n.tapYourCard,
      child: CenteredLayout(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ScanCardButton.needed) ...[ScanCardButton(label: l10n.scanCard), context.space.gapMd],
            FarmTapButton(
              label: l10n.enterCardInstead,
              icon: Symbols.dialpad_rounded,
              kind: ButtonKind.outlined,
              onPressed: widget.onTypeNumber,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextAction(label: l10n.ownerSignIn, onPressed: widget.onOwnerSignIn, small: true),
                ExcludeSemantics(child: Text(' · ', style: context.text.labelMedium)),
                TextAction(label: l10n.switchFarm2, onPressed: widget.onSwitchFarm, small: true),
              ],
            ),
            if (widget.showSimulate) TextAction(label: l10n.simulateTap, onPressed: _simulate, small: true),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FarmTapLogo(height: context.sizes.authLogoHeight),
            Text(widget.farmName, style: context.text.bodySmall),
            context.space.gapXxl,
            FarmTapAnimationView(animation: FarmTapAnimations.tapCard, size: context.sizes.animationMd),
            context.space.gapXxl,
            Text(l10n.tapYourCard, textAlign: TextAlign.center, style: context.text.titleMedium),
            context.space.gapXs,
            Text(l10n.tapYourCardBody, textAlign: TextAlign.center, style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// C05 — NFC is turned off (or the phone has none): type the number. The
/// person turns NFC on in the phone's own settings; the page reads cards
/// again when it next opens.
Future<void> showNfcOffDialog(BuildContext context, {VoidCallback? onTypeNumber}) async {
  final l10n = AppLocalizations.of(context);
  final type = await showFarmTapDialog(
    context,
    icon: Symbols.contactless_rounded,
    tone: FarmTapTone.gold,
    title: l10n.nfcOffTitle,
    message: l10n.nfcOffBody,
    primaryLabel: l10n.typeCardNumber,
    primaryIcon: Symbols.dialpad_rounded,
    secondaryLabel: l10n.cancel,
    secondaryKind: ButtonKind.text,
  );
  if (type) onTypeNumber?.call();
}

/// C02 — type the card number.
class CardNumberPage extends StatefulWidget {
  const new({required this.access, required this.onFound, super.key});

  final StaffAccessRepository access;
  final ValueChanged<StaffMember> onFound;

  @override
  State<CardNumberPage> createState() => _CardNumberPageState();
}

class _CardNumberPageState extends State<CardNumberPage> {
  String _number = '';
  String? _error;

  Future<void> _next() async {
    final l10n = AppLocalizations.of(context);
    final found = (await widget.access.findByCard(_number)).data;
    if (!mounted) return;
    if (found == null) {
      setState(() => _error = l10n.cardNotFound);
      return;
    }
    widget.onFound(found);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SplitAuthLayout(
      animation: FarmTapAnimations.welcome,
      tagline: l10n.brandTagline,
      description: l10n.brandBody,
      header: const AuthBackButton(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeading(title: l10n.cardNumberTitle, subtitle: l10n.cardNumberSubtitle),
          context.space.gapLg,
          KeypadDisplay(text: _number, placeholder: ''),
          if (_error != null) ...[
            context.space.gapSm,
            Text(_error!, style: context.text.bodySmall?.copyWith(color: context.colors.error)),
          ],
          context.space.gapLg,
          Center(
            child: BigNumberKeypad(
              onDigit: (d) => setState(() {
                _error = null;
                if (_number.length < 4) _number += d;
              }),
              onBackspace: () => setState(() {
                _error = null;
                if (_number.isNotEmpty) _number = _number.substring(0, _number.length - 1);
              }),
            ),
          ),
          context.space.gapSm,
          FarmTapButton(label: l10n.next, icon: Symbols.check_rounded, onPressed: _number.length == 4 ? _next : null),
        ],
      ),
    );
  }
}

/// C03 — enter your PIN; C04 is the wrong-PIN state (dots shake, red ring,
/// tries left). After 5 wrong tries the card locks for 5 minutes.
class StaffPinPage extends StatefulWidget {
  const new({
    required this.staff,
    required this.access,
    required this.onUnlocked,
    super.key,
    this.onNotMe,
    this.onNewPin,
  });

  /// A manager set this PIN: the worker chooses their own before going on
  /// (decision 0016 §5). Saves it; null skips the step.
  final Future<void> Function(StaffMember staff, String pin)? onNewPin;

  final StaffMember staff;
  final StaffAccessRepository access;
  final ValueChanged<StaffMember> onUnlocked;
  final VoidCallback? onNotMe;

  @override
  State<StaffPinPage> createState() => _StaffPinPageState();
}

class _StaffPinPageState extends State<StaffPinPage> {
  String _pin = '';
  int _shakes = 0;
  PinCheck? _last;
  bool _busy = false;

  bool get _wrong => _last is PinRejected || _last is PinLocked;

  Future<void> _digit(String d) async {
    if (_busy || _last is PinLocked) return;
    setState(() {
      if (_wrong) _last = null;
      _pin += d;
    });
    if (_pin.length < 4) return;
    _busy = true;
    final check = (await widget.access.verifyPin(widget.staff.id, _pin)).data;
    if (!mounted) return;
    _busy = false;
    if (check is PinAccepted) {
      final save = widget.onNewPin;
      if (check.mustChange && save != null) {
        final pin = await showChooseNewPin(context, name: widget.staff.greetingName);
        if (!mounted) return;
        if (pin == null) {
          setState(() => _pin = '');
          return;
        }
        await save(widget.staff, pin);
        if (!mounted) return;
        FarmTapToast.show(context, message: AppLocalizations.of(context).pinChangedToast);
      }
      widget.onUnlocked(widget.staff);
      return;
    }
    setState(() {
      _last = check;
      _pin = '';
      _shakes++;
    });
  }

  void _back() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final last = _last;
    final message = switch (last) {
      PinRejected(:final triesLeft) => l10n.wrongPinTries(triesLeft),
      PinLocked() => l10n.cardLocked,
      _ => l10n.enterPin,
    };
    return CenteredLayout(
      top: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.space.sm),
        child: const AuthBackButton(),
      ),
      bottom: _wrong
          ? Text(l10n.forgotPin, textAlign: TextAlign.center, style: context.text.bodySmall)
          : TextAction(label: l10n.notYou(widget.staff.greetingName), onPressed: widget.onNotMe, small: true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PersonAvatar(
            name: widget.staff.name,
            photo: widget.staff.photo,
            size: context.sizes.avatarReadBack,
            ring: true,
            ringColor: _wrong ? context.status.danger : null,
          ),
          context.space.gapMd,
          Text(l10n.helloName(widget.staff.greetingName), style: context.text.titleLarge),
          context.space.gapXs,
          Semantics(
            liveRegion: true,
            child: Text(message, textAlign: TextAlign.center, style: context.text.bodySmall),
          ),
          context.space.gapLg,
          PinDots(filled: _wrong ? 4 : _pin.length, error: _wrong, errorTick: _shakes),
          context.space.gapXl,
          BigNumberKeypad(pill: true, onDigit: _digit, onBackspace: _back),
        ],
      ),
    );
  }
}
