import 'dart:convert';
import 'dart:typed_data';

import 'package:farm_tap/core/nfc/card_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_manager/ndef_record.dart';

void main() {
  NdefRecord text(String t) => NdefRecord(
    typeNameFormat: TypeNameFormat.wellKnown,
    type: Uint8List.fromList([0x54]),
    identifier: Uint8List(0),
    payload: Uint8List.fromList([2, ...utf8.encode('en'), ...utf8.encode(t)]),
  );

  test('a card with its printed number as NDEF text reads as that number', () {
    expect(NfcCardReader.normalise(NfcCardReader.ndefText(text('0142'))!), '0142');
    expect(NfcCardReader.normalise(NfcCardReader.ndefText(text('FT 142'))!), '0142');
  });

  test('other records are not card numbers', () {
    final uri = NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x55]),
      identifier: Uint8List(0),
      payload: Uint8List.fromList([1, ...utf8.encode('farmtap.app')]),
    );
    expect(NfcCardReader.ndefText(uri), isNull);
    expect(NfcCardReader.normalise('no digits'), isEmpty);
  });

  test('a blank card reads as its chip id', () {
    expect(NfcCardReader.chipId(Uint8List.fromList([0x04, 0xa2, 0x0b])), '04A20B');
  });
}
