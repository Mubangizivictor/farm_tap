import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

/// Reads FarmTap staff and farmer cards (decision 0006). Widgets use
/// [CardReader.instance]; the app swaps in [NfcCardReader] at start-up and
/// tests keep the silent one.
abstract class CardReader {
  static CardReader instance = NoCardReader();

  /// The phone has NFC and it is turned on.
  Future<bool> available();

  /// Listens for cards until [stop]; [onCard] gets the card number.
  Future<void> start(ValueChanged<String> onCard, {String? prompt});

  Future<void> stop();
}

/// Tests and the simulator: never reads a card, never asks to turn NFC on.
class NoCardReader implements CardReader {
  @override
  Future<bool> available() async => true;

  @override
  Future<void> start(ValueChanged<String> onCard, {String? prompt}) async {}

  @override
  Future<void> stop() async {}
}

class NfcCardReader implements CardReader {
  var _running = false;

  @override
  Future<bool> available() async {
    try {
      return await NfcManager.instance.checkAvailability() == NfcAvailability.enabled;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> start(ValueChanged<String> onCard, {String? prompt}) async {
    if (_running || !await available()) return;
    _running = true;
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        alertMessageIos: prompt,
        // Android keeps listening while the page is open; iOS shows one
        // system sheet per card.
        onSessionErrorIos: (_) => _running = false,
        onDiscovered: (tag) {
          final number = cardNumber(tag);
          if (number == null) return;
          if (!kIsWeb && Platform.isIOS) {
            _running = false;
          }
          onCard(number);
        },
      );
    } on Object {
      _running = false;
    }
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    try {
      await NfcManager.instance.stopSession();
    } on Object {
      // Already closed.
    }
  }

  /// The printed number if the card carries it as NDEF text, else its chip id.
  static String? cardNumber(NfcTag tag) {
    final message = switch (defaultTargetPlatform) {
      TargetPlatform.android => NdefAndroid.from(tag)?.cachedNdefMessage,
      TargetPlatform.iOS => NdefIos.from(tag)?.cachedNdefMessage,
      _ => null,
    };
    for (final r in message?.records ?? const <NdefRecord>[]) {
      final text = ndefText(r);
      if (text != null) {
        final n = normalise(text);
        if (n.isNotEmpty) return n;
      }
    }
    final id = switch (defaultTargetPlatform) {
      TargetPlatform.android => NfcTagAndroid.from(tag)?.id,
      TargetPlatform.iOS =>
        MiFareIos.from(tag)?.identifier ?? Iso15693Ios.from(tag)?.identifier ?? Iso7816Ios.from(tag)?.identifier,
      _ => null,
    };
    return id == null ? null : chipId(id);
  }

  /// An NDEF well-known text record ("T"), else null.
  static String? ndefText(NdefRecord r) {
    if (r.typeNameFormat != TypeNameFormat.wellKnown || r.type.length != 1 || r.type.first != 0x54) return null;
    if (r.payload.isEmpty) return null;
    final langLength = r.payload.first & 0x3F;
    if (r.payload.length <= 1 + langLength) return null;
    return utf8.decode(r.payload.sublist(1 + langLength), allowMalformed: true);
  }

  /// "FT 0142", "142" -> "0142": the digits, at least four.
  static String normalise(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? '' : digits.padLeft(4, '0');
  }

  /// Chip id as upper-case hex, e.g. "04A2B3C4D5E680".
  static String chipId(Uint8List id) => [for (final b in id) b.toRadixString(16).padLeft(2, '0')].join().toUpperCase();
}
