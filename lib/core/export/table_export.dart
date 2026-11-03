// Download / export for any list in the app: the person picks a PDF (to
// print or send on WhatsApp) or a spreadsheet (CSV, opens in Excel and
// Google Sheets). Both are made on the phone, so they work offline.
import 'dart:convert';
import 'dart:typed_data';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// One table to export: a title line, then a header row and the rows.
class ExportTable {
  const new({required this.title, required this.headers, required this.rows, this.subtitle, this.footer = const []});

  final String title;
  final String? subtitle;
  final List<String> headers;
  final List<List<String>> rows;

  /// Total lines under the table ("Total", "UGX 1,200,000").
  final List<List<String>> footer;

  /// A safe file name from the title: "Milk sales 3 Nov" -> "milk-sales-3-nov".
  String get fileStem {
    final s = title.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    return s.isEmpty ? 'farmtap' : 'farmtap-$s';
  }

  /// RFC 4180 CSV with a BOM so Excel reads UGX and names correctly.
  Uint8List toCsv() {
    String cell(String v) => v.contains(RegExp('[",\n]')) ? '"${v.replaceAll('"', '""')}"' : v;
    final lines = [
      cell(title),
      if (subtitle != null) cell(subtitle!),
      '',
      headers.map(cell).join(','),
      for (final r in rows) r.map(cell).join(','),
      if (footer.isNotEmpty) '',
      for (final r in footer) r.map(cell).join(','),
    ];
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(lines.join('\r\n'))]);
  }

  /// A4 PDF, the table across the page (more pages when it is long).
  Future<Uint8List> toPdf({required String farmName}) {
    final doc = pw.Document()
      ..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(FarmTapPrint.pageMargin),
          header: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (farmName.isNotEmpty) pw.Text(farmName, style: FarmTapPrint.small),
              pw.Text(title, style: FarmTapPrint.title),
              if (subtitle != null) pw.Text(subtitle!, style: FarmTapPrint.small),
              pw.SizedBox(height: FarmTapPrint.blockGap),
            ],
          ),
          footer: (c) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('FarmTap  ·  ${c.pageNumber} / ${c.pagesCount}', style: FarmTapPrint.small),
          ),
          build: (_) => [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: FarmTapPrint.tableHeader,
              cellStyle: FarmTapPrint.tableCell,
              headerDecoration: const pw.BoxDecoration(color: FarmTapPrint.headerFill),
              border: pw.TableBorder.all(width: FarmTapPrint.labelBorder, color: FarmTapPrint.rule),
              cellPadding: const pw.EdgeInsets.all(FarmTapPrint.cellPadding),
            ),
            if (footer.isNotEmpty) ...[
              pw.SizedBox(height: FarmTapPrint.blockGap),
              for (final r in footer)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [for (final c in r) pw.Text(c, style: FarmTapPrint.tableHeader)],
                ),
            ],
          ],
        ),
      );
    return doc.save();
  }
}

enum _Format { pdf, csv }

/// Asks PDF or spreadsheet, then opens the phone's share sheet (WhatsApp,
/// email, Files, print). Works offline.
Future<void> exportTable(BuildContext context, ExportTable table, {String farmName = ''}) async {
  final l10n = AppLocalizations.of(context);
  final format = await showAdaptiveSheet<_Format>(
    context,
    builder: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(l10n.exportLabel, subtitle: table.title),
        sheet.space.gapMd,
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const IconBubble(icon: Symbols.picture_as_pdf_rounded, tone: FarmTapTone.danger),
          title: Text(l10n.exportPdf),
          subtitle: Text(l10n.exportPdfSub),
          onTap: () => Navigator.of(sheet).pop(_Format.pdf),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const IconBubble(icon: Symbols.table_view_rounded, tone: FarmTapTone.success),
          title: Text(l10n.exportSheet),
          subtitle: Text(l10n.exportSheetSub),
          onTap: () => Navigator.of(sheet).pop(_Format.csv),
        ),
      ],
    ),
  );
  if (format == null || !context.mounted) return;
  if (table.rows.isEmpty) {
    FarmTapToast.show(context, message: l10n.nothingToExport, tone: FarmTapTone.warning, icon: Symbols.info_rounded);
    return;
  }
  try {
    switch (format) {
      case _Format.pdf:
        await Printing.sharePdf(
          bytes: await table.toPdf(farmName: farmName),
          filename: '${table.fileStem}.pdf',
        );
      case _Format.csv:
        await SharePlus.instance.share(
          ShareParams(
            title: table.title,
            files: [XFile.fromData(table.toCsv(), mimeType: 'text/csv', name: '${table.fileStem}.csv')],
            fileNameOverrides: ['${table.fileStem}.csv'],
          ),
        );
    }
  } on Object {
    if (context.mounted) {
      FarmTapToast.show(context, message: l10n.exportFailed, tone: FarmTapTone.danger, icon: Symbols.error_rounded);
    }
  }
}
