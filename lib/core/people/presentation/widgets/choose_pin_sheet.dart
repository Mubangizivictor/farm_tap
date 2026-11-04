// Choose your own PIN (decision 0016 §5): asked after a manager set or
// reset the PIN. Typed twice; easy PINs (1234, 0000) are refused.
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/people/domain/staff_member.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';

/// The new PIN, or null when the sheet was closed.
Future<String?> showChooseNewPin(BuildContext context, {String? name}) =>
    showAdaptiveSheet<String>(context, dismissible: false, builder: (_) => _ChoosePin(name: name));

class _ChoosePin extends StatefulWidget {
  const new({this.name});

  final String? name;

  @override
  State<_ChoosePin> createState() => _ChoosePinState();
}

class _ChoosePinState extends State<_ChoosePin> {
  String? _first;
  String? _error;
  int _key = 0;

  Future<bool> _done(String pin) async {
    final l10n = AppLocalizations.of(context);
    if (_first == null) {
      if (weakPin(pin)) {
        setState(() {
          _error = l10n.pinTooEasy;
          _key++;
        });
        return false;
      }
      setState(() {
        _first = pin;
        _error = null;
        _key++;
      });
      return true;
    }
    if (pin != _first) {
      setState(() {
        _first = null;
        _error = l10n.pinsDoNotMatch;
        _key++;
      });
      return false;
    }
    Navigator.of(context).pop(pin);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(
          _first == null ? l10n.chooseOwnPinTitle : l10n.confirmPinTitle,
          subtitle: _first == null ? l10n.chooseOwnPinBody : l10n.confirmPinBody,
          center: true,
        ),
        if (_error != null) ...[
          context.space.gapSm,
          Text(_error!, style: context.text.bodyMedium?.copyWith(color: context.colors.error)),
        ],
        context.space.gapLg,
        PinPad(key: ValueKey(_key), onCompleted: _done),
      ],
    );
  }
}
