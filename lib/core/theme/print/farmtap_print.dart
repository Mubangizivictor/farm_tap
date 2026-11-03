// Sizes and text styles for printed documents (pdf package), in PDF points
// (1/72 inch). Used by the ear-tag label sheet (E10) and later statements.
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

abstract final class FarmTapPrint {
  static const double labelWidth = 160;
  static const double labelPadding = 8;
  static const double labelGap = 12;
  static const double labelQr = 56;
  static const double labelInnerGap = 8;
  static const double labelBorder = 0.5;

  // ---- ID cards (decision 0015): ISO/IEC 7810 ID-1 (CR80) ----
  /// 85.6 x 53.98 mm in PDF points.
  static const double cardWidth = 85.6 * mm;
  static const double cardHeight = 53.98 * mm;
  static const double mm = 72 / 25.4;
  static const double cardRadius = 3 * mm;
  static const double cardPadding = 3.2 * mm;
  static const double cardBand = 7 * mm;
  static const double cardPhotoWidth = 20 * mm;
  static const double cardPhotoHeight = 25 * mm;
  static const double cardQr = 16 * mm;
  static const double cardGap = 2 * mm;
  static const double cardSmallGap = 1 * mm;
  static const double cardBorder = 0.4;

  /// A4 sheet of cards: 2 across, 4 down, with cut marks.
  static const double sheetMargin = 12 * mm;
  static const double sheetGap = 6 * mm;
  static const double cutMark = 3 * mm;
  static const double cutMarkStroke = 0.3;

  /// Card colours (print is always light): FarmTap green and gold.
  static const PdfColor cardGreen = PdfColor.fromInt(0xFF1F5E4A);
  static const PdfColor cardGreenSoft = PdfColor.fromInt(0xFFCFE9DF);
  static const PdfColor cardGold = PdfColor.fromInt(0xFFC98A0E);
  static const PdfColor cardInk = PdfColor.fromInt(0xFF1B1F1D);
  static const PdfColor cardMuted = PdfColor.fromInt(0xFF5E6762);
  static const PdfColor cardWhite = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor cardLine = PdfColor.fromInt(0xFFCBD3CE);
  static const PdfColor cardDanger = PdfColor.fromInt(0xFFB3261E);

  static const pw.TextStyle cardFarm = pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: cardWhite);
  static const pw.TextStyle cardKind = pw.TextStyle(fontSize: 6, color: cardWhite, letterSpacing: 0.6);
  static const pw.TextStyle cardName = pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: cardInk);
  static const pw.TextStyle cardLabel = pw.TextStyle(fontSize: 5.5, color: cardMuted, letterSpacing: 0.3);
  static const pw.TextStyle cardValue = pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: cardInk);
  static const pw.TextStyle cardNumber = pw.TextStyle(
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: cardGreen,
    letterSpacing: 1.5,
  );
  static const pw.TextStyle cardSmall = pw.TextStyle(fontSize: 6, color: cardMuted);
  static const pw.TextStyle cardInitials = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: cardGreen);

  static const pw.TextStyle tag = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
  static const pw.TextStyle small = pw.TextStyle(fontSize: 9);
}
