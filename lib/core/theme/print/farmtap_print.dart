// Sizes and text styles for printed documents (pdf package), in PDF points
// (1/72 inch). Used by the ear-tag label sheet (E10) and later statements.
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
}
