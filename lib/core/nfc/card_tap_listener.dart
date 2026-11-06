import 'dart:async';

import 'package:farm_tap/core/nfc/card_reader.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Reads cards while [child] is on screen: put it on a "Tap your card" page
/// and handle [onCard]. Several pages can listen (tabs keep pages alive);
/// the newest one on the visible route gets the card. The reader stops
/// when the last one leaves.
class CardTapListener extends StatefulWidget {
  const new({
    required this.onCard,
    required this.child,
    super.key,
    this.enabled = true,
    this.prompt,
    this.autoOpenOnIos = true,
  });

  /// iPhone: open Apple's scan sheet as soon as the page shows. False on
  /// pages with a form (the sheet would cover it); they show a
  /// [ScanCardButton] instead. Android always listens.
  final bool autoOpenOnIos;

  final ValueChanged<String> onCard;
  final Widget child;
  final bool enabled;

  /// iOS shows this on the system NFC sheet.
  final String? prompt;

  /// Reads the next card for the listener on screen (see the state's
  /// scanAgain). False when no page on screen is listening.
  static bool scanAgain() => _CardTapListenerState.scanAgain();

  @override
  State<CardTapListener> createState() => _CardTapListenerState();
}

class _CardTapListenerState extends State<CardTapListener> {
  static final List<_CardTapListenerState> _active = [];

  String? _last;
  final _sinceLast = Stopwatch();

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _active.add(this);
  }

  /// Back on this page (iOS ends the reader after each card): read again.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.enabled && _onScreen && _auto) {
      _sinceLast
        ..stop()
        ..reset();
      unawaited(CardReader.instance.start(_dispatch, prompt: widget.prompt));
    }
  }

  @override
  void didUpdateWidget(CardTapListener old) {
    super.didUpdateWidget(old);
    if (old.enabled != widget.enabled) widget.enabled ? _join() : _leave();
  }

  void _join() {
    _active.add(this);
    // Only the page on screen starts the reader (on iOS that opens the scan
    // sheet); pages kept alive in other tabs wait. didChangeDependencies
    // starts it right after initState.
    if (mounted && _onScreen && _auto) unawaited(CardReader.instance.start(_dispatch, prompt: widget.prompt));
  }

  bool get _auto => widget.autoOpenOnIos || !ScanCardButton.needed;

  bool get _onScreen => (ModalRoute.of(context)?.isCurrent ?? true) && TickerMode.valuesOf(context).enabled;

  void _leave() {
    _active.remove(this);
    if (_active.isEmpty) unawaited(CardReader.instance.stop());
  }

  /// Reads the next card for the listener on screen. On iPhone each read
  /// opens Apple's scan sheet once, so pages offer a "Scan card" button;
  /// on Android the reader is already listening and this changes nothing.
  /// Returns false when no page on screen is listening.
  static bool scanAgain() {
    for (final l in _active.reversed) {
      if (l.mounted && l.widget.enabled && l._onScreen) {
        l._sinceLast
          ..stop()
          ..reset();
        unawaited(CardReader.instance.start(_dispatch, prompt: l.widget.prompt));
        return true;
      }
    }
    return false;
  }

  static void _dispatch(String card) {
    for (final l in _active.reversed) {
      if (l.mounted && (ModalRoute.of(l.context)?.isCurrent ?? true) && TickerMode.valuesOf(l.context).enabled) {
        l._read(card);
        return;
      }
    }
  }

  void _read(String card) {
    // A card held on the phone can be seen twice; one read per tap.
    if (card == _last && _sinceLast.isRunning && _sinceLast.elapsed.inSeconds < 3) return;
    _last = card;
    _sinceLast
      ..reset()
      ..start();
    unawaited(HapticFeedback.mediumImpact());
    widget.onCard(card);
  }

  @override
  void dispose() {
    if (widget.enabled) _leave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// "Scan card": on iPhone, opens Apple's scan sheet for the next card. Shown
/// only where the phone needs it (iOS); elsewhere the reader is always on.
class ScanCardButton extends StatelessWidget {
  const new({required this.label, super.key, this.large = false, this.force = false});

  final String label;
  final bool large;

  /// Show it on every platform (e.g. when it is the page's main action).
  final bool force;

  static bool get needed => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    if (!force && !needed) return const SizedBox.shrink();
    return FarmTapButton(
      label: label,
      icon: Symbols.contactless_rounded,
      large: large,
      onPressed: CardTapListener.scanAgain,
    );
  }
}
