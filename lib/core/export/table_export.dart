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

  /// The table (and its footer) as PDF widgets, under an optional heading.
  List<pw.Widget> pdfBody({bool heading = false}) => [
    if (heading) ...[
      pw.Text(title, style: FarmTapPrint.heading),
      if (subtitle != null) pw.Text(subtitle!, style: FarmTapPrint.small),
      pw.SizedBox(height: FarmTapPrint.cellPadding),
    ],
    if (rows.isEmpty)
      pw.Text('—', style: FarmTapPrint.tableCell)
    else
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
      pw.SizedBox(height: FarmTapPrint.cellPadding),
      for (final r in footer)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [for (final c in r) pw.Text(c, style: FarmTapPrint.tableHeader)],
        ),
    ],
  ];

  /// A4 PDF, the table across the page (more pages when it is long).
  Future<Uint8List> toPdf({required String farmName}) =>
      ExportReport(title: title, subtitle: subtitle, tables: [this], single: true).toPdf(farmName: farmName);
}

/// A report of several tables (monthly farm report): one PDF with a section
/// per table, or one spreadsheet file per table.
class ExportReport {
  const new({required this.title, required this.tables, this.subtitle, this.summary = const [], this.single = false});

  final String title;
  final String? subtitle;

  /// Label / value lines at the top ("Milk produced", "8,742 L").
  final List<(String, String)> summary;
  final List<ExportTable> tables;

  /// One table only: no section heading.
  final bool single;

  String get fileStem => ExportTable(title: title, headers: const [], rows: const []).fileStem;

  Future<Uint8List> toPdf({required String farmName}) {
    final doc = pw.Document()
      ..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(FarmTapPrint.pageMargin),
          header: (c) => c.pageNumber > 1
              ? pw.SizedBox()
              : pw.Column(
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
            for (final (label, value) in summary)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(label, style: FarmTapPrint.tableCell),
                  pw.Text(value, style: FarmTapPrint.tableHeader),
                ],
              ),
            if (summary.isNotEmpty) pw.SizedBox(height: FarmTapPrint.blockGap),
            for (final t in tables) ...[...t.pdfBody(heading: !single), pw.SizedBox(height: FarmTapPrint.blockGap)],
          ],
        ),
      );
    return doc.save();
  }
}

enum _Format { pdf, csv }

/// Asks PDF or spreadsheet, then opens the phone's share sheet (WhatsApp,
/// email, Files, print). Works offline.
Future<void> exportTable(BuildContext context, ExportTable table, {String farmName = ''}) => exportReport(
  context,
  ExportReport(title: table.title, subtitle: table.subtitle, tables: [table], single: true),
  farmName: farmName,
);

/// [exportTable] for a report of several tables. [pdfOnly] skips the
/// question (a printed report).
Future<void> exportReport(
  BuildContext context,
  ExportReport report, {
  String farmName = '',
  bool pdfOnly = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final format = pdfOnly
      ? _Format.pdf
      : await showAdaptiveSheet<_Format>(
          context,
          builder: (sheet) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetTitle(l10n.exportLabel, subtitle: report.title),
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
  if (report.tables.every((t) => t.rows.isEmpty) && report.summary.isEmpty) {
    FarmTapToast.show(context, message: l10n.nothingToExport, tone: FarmTapTone.warning, icon: Symbols.info_rounded);
    return;
  }
  try {
    switch (format) {
      case _Format.pdf:
        await Printing.sharePdf(
          bytes: await report.toPdf(farmName: farmName),
          filename: '${report.fileStem}.pdf',
        );
      case _Format.csv:
        final names = [for (final t in report.tables) '${t.fileStem}.csv'];
        await SharePlus.instance.share(
          ShareParams(
            title: report.title,
            files: [
              for (var i = 0; i < report.tables.length; i++)
                XFile.fromData(report.tables[i].toCsv(), mimeType: 'text/csv', name: names[i]),
            ],
            fileNameOverrides: names,
          ),
        );
    }
  } on Object {
    if (context.mounted) {
      FarmTapToast.show(context, message: l10n.exportFailed, tone: FarmTapTone.danger, icon: Symbols.error_rounded);
    }
  }
}
