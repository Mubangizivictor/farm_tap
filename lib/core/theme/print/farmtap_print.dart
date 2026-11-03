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

  static const pw.TextStyle tag = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
  static const pw.TextStyle small = pw.TextStyle(fontSize: 9);

  // Exported tables and reports (A4).
  static const double pageMargin = 32;
  static const double blockGap = 10;
  static const double cellPadding = 4;
  static const pw.TextStyle title = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold);
  static const pw.TextStyle heading = pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold);
  static const pw.TextStyle tableHeader = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
  static const pw.TextStyle tableCell = pw.TextStyle(fontSize: 9);
  static const PdfColor headerFill = PdfColor.fromInt(0xFFE8F0E8);
  static const PdfColor rule = PdfColor.fromInt(0xFF9E9E9E);
}
