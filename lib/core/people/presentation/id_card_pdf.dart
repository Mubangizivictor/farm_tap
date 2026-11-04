// Printable ID cards (decision 0016 §3): one card (front + back pages at
// CR80 size, for a card printer) or a sheet of cards on A4 with cut marks
// (for a normal printer; cut out and laminate).
import 'dart:typed_data';

import 'package:farm_tap/core/people/domain/card_registry.dart';
import 'package:farm_tap/core/people/presentation/widgets/id_card.dart';
import 'package:farm_tap/core/theme/print/farmtap_print.dart';
import 'package:farm_tap/core/ui/avatars.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Words printed on the card (from the app's strings).
class IdCardWords {
  const new({
    required this.staff,
    required this.supplier,
    required this.department,
    required this.idNumber,
    required this.phone,
    required this.emergency,
    required this.village,
    required this.nin,
    required this.memberSince,
    required this.issued,
    required this.ifFound,
    required this.validNote,
    required this.scanMe,
    required this.date,
  });

  final String staff;
  final String supplier;
  final String department;
  final String idNumber;
  final String phone;
  final String emergency;
  final String village;
  final String nin;
  final String memberSince;
  final String issued;
  final String ifFound;
  final String validNote;
  final String scanMe;
  final String Function(DateTime) date;
}

abstract final class IdCardPdf {
  static const _cardFormat = PdfPageFormat(FarmTapPrint.cardWidth, FarmTapPrint.cardHeight);

  /// One card: page 1 front, page 2 back, each exactly CR80 size.
  static Future<Uint8List> single(IdCardData card, IdCardWords words) async {
    final doc = pw.Document(title: card.name, author: card.farmName)
      ..addPage(pw.Page(pageFormat: _cardFormat, build: (_) => front(card, words)))
      ..addPage(pw.Page(pageFormat: _cardFormat, build: (_) => back(card, words)));
    return await doc.save();
  }

  /// Many cards on A4: 2 across and 4 down; each front sheet is followed by
  /// its back sheet, mirrored so the backs line up when printed two-sided.
  static Future<Uint8List> sheet(List<IdCardData> cards, IdCardWords words) async {
    final doc = pw.Document(title: cards.isEmpty ? '' : cards.first.farmName);
    const perPage = 8;
    for (var i = 0; i < cards.length; i += perPage) {
      final page = cards.sublist(i, i + perPage > cards.length ? cards.length : i + perPage);
      doc
        ..addPage(_sheetPage([for (final c in page) front(c, words)]))
        ..addPage(_sheetPage([for (final c in page) back(c, words)], mirror: true));
    }
    return await doc.save();
  }

  static pw.Page _sheetPage(List<pw.Widget> cards, {bool mirror = false}) => pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(FarmTapPrint.sheetMargin),
    build: (_) {
      final rows = <pw.Widget>[];
      for (var r = 0; r < cards.length; r += 2) {
        final pair = [
          _cut(cards[r]),
          if (r + 1 < cards.length) _cut(cards[r + 1]) else pw.SizedBox(width: FarmTapPrint.cardWidth),
        ];
        rows.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: FarmTapPrint.sheetGap),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                ...(mirror ? pair.reversed : pair).expand((w) => [w, pw.SizedBox(width: FarmTapPrint.sheetGap)]),
              ]..removeLast(),
            ),
          ),
        );
      }
      return pw.Column(children: rows);
    },
  );

  /// A card with cut marks at its corners.
  static pw.Widget _cut(pw.Widget card) => pw.Stack(
    overflow: pw.Overflow.visible,
    children: [
      pw.SizedBox(width: FarmTapPrint.cardWidth, height: FarmTapPrint.cardHeight, child: card),
      for (final (x, y) in const [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)]) ...[
        pw.Positioned(
          left: x * FarmTapPrint.cardWidth - (x == 0 ? FarmTapPrint.cutMark : 0),
          top: y * FarmTapPrint.cardHeight,
          child: pw.Container(
            width: FarmTapPrint.cutMark,
            height: FarmTapPrint.cutMarkStroke,
            color: FarmTapPrint.cardMuted,
          ),
        ),
        pw.Positioned(
          left: x * FarmTapPrint.cardWidth,
          top: y * FarmTapPrint.cardHeight - (y == 0 ? FarmTapPrint.cutMark : 0),
          child: pw.Container(
            width: FarmTapPrint.cutMarkStroke,
            height: FarmTapPrint.cutMark,
            color: FarmTapPrint.cardMuted,
          ),
        ),
      ],
    ],
  );

  static pw.Widget _shell({required pw.Widget band, required pw.Widget body}) => pw.Container(
    width: FarmTapPrint.cardWidth,
    height: FarmTapPrint.cardHeight,
    decoration: pw.BoxDecoration(
      color: FarmTapPrint.cardWhite,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(FarmTapPrint.cardRadius)),
      border: pw.Border.all(color: FarmTapPrint.cardLine, width: FarmTapPrint.cardBorder),
    ),
    child: pw.ClipRRect(
      horizontalRadius: FarmTapPrint.cardRadius,
      verticalRadius: FarmTapPrint.cardRadius,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            height: FarmTapPrint.cardBand,
            color: FarmTapPrint.cardGreen,
            padding: const pw.EdgeInsets.symmetric(horizontal: FarmTapPrint.cardPadding),
            alignment: pw.Alignment.centerLeft,
            child: band,
          ),
          pw.Expanded(
            child: pw.Padding(padding: const pw.EdgeInsets.all(FarmTapPrint.cardPadding), child: body),
          ),
          pw.Container(height: FarmTapPrint.cardSmallGap, color: FarmTapPrint.cardGold),
        ],
      ),
    ),
  );

  static pw.Widget _field(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: FarmTapPrint.cardHalfGap),
    child: pw.RichText(
      maxLines: 1,
      overflow: pw.TextOverflow.clip,
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: '${label.toUpperCase()}  ', style: FarmTapPrint.cardLabel),
          pw.TextSpan(text: value, style: FarmTapPrint.cardValue),
        ],
      ),
    ),
  );

  static pw.Widget _photo(IdCardData card) {
    final bytes = PersonAvatar.photoBytes(card.photo);
    const box = pw.BoxDecoration(
      color: FarmTapPrint.cardGreenSoft,
      borderRadius: pw.BorderRadius.all(pw.Radius.circular(FarmTapPrint.cardSmallGap * 1.5)),
    );
    return pw.Container(
      width: FarmTapPrint.cardPhotoWidth,
      height: FarmTapPrint.cardPhotoHeight,
      decoration: box,
      alignment: pw.Alignment.center,
      child: bytes == null
          ? pw.Text(PersonAvatar.initialsOf(card.name), style: FarmTapPrint.cardInitials)
          : pw.ClipRRect(
              horizontalRadius: FarmTapPrint.cardSmallGap * 1.5,
              verticalRadius: FarmTapPrint.cardSmallGap * 1.5,
              child: pw.Image(
                pw.MemoryImage(bytes),
                width: FarmTapPrint.cardPhotoWidth,
                height: FarmTapPrint.cardPhotoHeight,
                fit: pw.BoxFit.cover,
              ),
            ),
    );
  }

  static pw.Widget front(IdCardData card, IdCardWords w) {
    final qr = card.qr;
    return _shell(
      band: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(card.farmName, style: FarmTapPrint.cardFarm, maxLines: 1)),
          pw.Text(
            (card.kind == CardHolderKind.staff ? w.staff : w.supplier).toUpperCase(),
            style: FarmTapPrint.cardKind,
          ),
        ],
      ),
      body: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _photo(card),
          pw.SizedBox(width: FarmTapPrint.cardGap),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(card.name, style: FarmTapPrint.cardName, maxLines: 2),
                if ((card.job ?? '').isNotEmpty)
                  pw.Text(card.job!, style: FarmTapPrint.cardSmall.copyWith(color: FarmTapPrint.cardGreen)),
                if ((card.department ?? '').isNotEmpty) _field(w.department, card.department!),
                pw.Spacer(),
                _field(w.idNumber, card.personCode),
                pw.Text(card.cardNumber ?? '----', style: FarmTapPrint.cardNumber),
              ],
            ),
          ),
          if (qr != null) ...[
            pw.SizedBox(width: FarmTapPrint.cardSmallGap),
            pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qr,
                  width: FarmTapPrint.cardQr,
                  height: FarmTapPrint.cardQr,
                  color: FarmTapPrint.cardInk,
                ),
                pw.Text(w.scanMe, style: FarmTapPrint.cardSmall),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget back(IdCardData card, IdCardWords w) {
    final rows = <(String, String)>[
      if ((card.phone ?? '').isNotEmpty) (w.phone, card.phone!),
      if ((card.emergencyName ?? '').isNotEmpty || (card.emergencyPhone ?? '').isNotEmpty)
        (w.emergency, [card.emergencyName, card.emergencyPhone].whereType<String>().join(' · ')),
      if ((card.village ?? '').isNotEmpty) (w.village, card.village!),
      if ((card.nationalId ?? '').isNotEmpty) (w.nin, card.nationalId!),
      if (card.since != null) (w.memberSince, w.date(card.since!)),
      if (card.issued != null) (w.issued, w.date(card.issued!)),
    ];
    return _shell(
      band: pw.Text(w.ifFound, style: FarmTapPrint.cardFarm.copyWith(fontWeight: pw.FontWeight.normal)),
      body: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final (label, value) in rows) _field(label, value),
          pw.Spacer(),
          pw.Text(
            [card.farmName, card.farmPlace, card.farmPhone].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
            style: FarmTapPrint.cardValue,
            maxLines: 1,
          ),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text(w.validNote, style: FarmTapPrint.cardSmall, maxLines: 2)),
              pw.Text(card.cardNumber ?? '', style: FarmTapPrint.cardNumber),
            ],
          ),
        ],
      ),
    );
  }
}
