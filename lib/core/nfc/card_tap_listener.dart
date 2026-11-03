import 'dart:async';

import 'package:farm_tap/core/nfc/card_reader.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Reads cards while [child] is on screen: put it on a "Tap your card" page
/// and handle [onCard]. Several pages can listen (tabs keep pages alive);
/// the newest one on the visible route gets the card. The reader stops
/// when the last one leaves.
class CardTapListener extends StatefulWidget {
  const new({required this.onCard, required this.child, super.key, this.enabled = true, this.prompt});

  final ValueChanged<String> onCard;
  final Widget child;
  final bool enabled;

  /// iOS shows this on the system NFC sheet.
  final String? prompt;

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
    if (widget.enabled && _onScreen) {
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
    if (mounted && _onScreen) unawaited(CardReader.instance.start(_dispatch, prompt: widget.prompt));
  }

  bool get _onScreen => (ModalRoute.of(context)?.isCurrent ?? true) && TickerMode.valuesOf(context).enabled;

  void _leave() {
    _active.remove(this);
    if (_active.isEmpty) unawaited(CardReader.instance.stop());
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
