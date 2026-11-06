// Receipt, invoice and refund note PDFs on the phone (decision 0024). Print
// layout, so it lives with the other print sizes in lib/core/theme/print. Same
// content and numbers as the web and server PDFs (shared/billing.ts):
// company header with logo, the document number, who paid, the lines, the
// total, PAID or REFUNDED, then the signature and stamp.

import 'dart:typed_data';

import 'package:farm_tap/core/billing/billing_repository.dart';
import 'package:farm_tap/core/theme/print/farmtap_print.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum DocView { receipt, invoice, refund }

String docNumberFor(BillingDocument d, DocView v) => switch (v) {
  DocView.receipt => d.receiptNo,
  DocView.invoice => d.invoiceNo,
  DocView.refund => d.refundNo ?? d.receiptNo,
};

String _ugx(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return 'UGX ${v < 0 ? '-' : ''}$b';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String _day(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

Future<Uint8List> buildBillingPdf(BillingDocument d, DocView view, BillingBrand brand) async {
  final doc = pw.Document(title: '${docNumberFor(d, view)} - FarmTap', author: brand.company);
  final title = switch (view) {
    DocView.receipt => 'RECEIPT',
    DocView.invoice => 'INVOICE',
    DocView.refund => 'REFUND NOTE',
  };
  pw.ImageProvider? img(List<int>? b) {
    if (b == null || b.isEmpty) return null;
    try {
      return pw.MemoryImage(Uint8List.fromList(b));
    } on Object {
      return null;
    }
  }

  final logo = img(brand.logo);
  final stamp = img(brand.stamp);
  final signature = img(brand.signature);
  const green = FarmTapPrint.cardGreen;
  const grey = FarmTapPrint.cardMuted;
  const small = pw.TextStyle(fontSize: 9, color: grey);
  const label = pw.TextStyle(fontSize: 8, color: grey, fontWeight: pw.FontWeight.bold, letterSpacing: 0.6);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null)
                pw.SizedBox(height: 48, width: 140, child: pw.Image(logo, alignment: pw.Alignment.centerLeft))
              else
                pw.Text(
                  'FarmTap',
                  style: const pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: green),
                ),
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(brand.company, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(brand.address, style: small),
                  pw.Text(brand.phone, style: small),
                  if (brand.email.isNotEmpty) pw.Text(brand.email, style: small),
                  pw.Text(brand.website, style: small),
                  if (brand.tin.isNotEmpty) pw.Text('TIN ${brand.tin}', style: small),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(height: 3, color: green),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: const pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: green),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('No. ${docNumberFor(d, view)}', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${_day(d.paidAt)}', style: small),
                    if (view == DocView.invoice) pw.Text('Receipt: ${d.receiptNo}', style: small),
                    if (view == DocView.refund && d.refundOf != null)
                      pw.Text('Refund of receipt ${d.refundOf}', style: small),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('BILLED TO', style: label),
                    pw.SizedBox(height: 2),
                    pw.Text(d.farmName, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    if (d.farmPlace.isNotEmpty) pw.Text(d.farmPlace, style: small),
                    if (d.billedTo.isNotEmpty) pw.Text(d.billedTo, style: small),
                    if (d.billedEmail.isNotEmpty) pw.Text(d.billedEmail, style: small),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.TableHelper.fromTextArray(
            headers: ['Description', 'Qty', 'Unit price', 'Amount'],
            data: [
              for (final i in d.items)
                [i.description, '${i.qty}', _ugx(i.unitUgx), _ugx(view == DocView.refund ? -i.amountUgx : i.amountUgx)],
            ],
            headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: green),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignments: {1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
            columnWidths: {
              0: const pw.FlexColumnWidth(5),
              1: const pw.FlexColumnWidth(),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(view == DocView.refund ? 'Refunded  ' : 'Total  ', style: const pw.TextStyle(color: grey)),
              pw.Text(
                _ugx(view == DocView.refund ? -d.totalUgx : d.totalUgx),
                style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            [
              'Paid by ${methodNames[d.method] ?? d.method}',
              if (d.reference.isNotEmpty) 'Transaction ID ${d.reference}',
              if (d.periodFrom != null && d.periodTo != null) 'Period ${_day(d.periodFrom!)} to ${_day(d.periodTo!)}',
            ].join('   ·   '),
            style: small,
          ),
          if (d.note.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(d.note, style: small),
            ),
          pw.SizedBox(height: 24),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Transform.rotate(
                angle: 0.2,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: view == DocView.refund ? FarmTapPrint.cardDanger : green, width: 2.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(
                    view == DocView.refund ? 'REFUNDED' : 'PAID',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: view == DocView.refund ? FarmTapPrint.cardDanger : green,
                    ),
                  ),
                ),
              ),
              pw.Spacer(),
              pw.SizedBox(
                width: 200,
                child: pw.Stack(
                  overflow: pw.Overflow.visible,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(height: 50, child: signature == null ? pw.SizedBox() : pw.Image(signature)),
                        pw.Container(height: 1, color: PdfColors.black),
                        pw.SizedBox(height: 4),
                        pw.Text(brand.signatoryName, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('${brand.signatoryTitle}, ${brand.company}', style: small),
                      ],
                    ),
                    if (stamp != null)
                      pw.Positioned(
                        right: -10,
                        top: -10,
                        child: pw.Opacity(
                          opacity: 0.85,
                          child: pw.SizedBox(width: 90, height: 90, child: pw.Image(stamp)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          pw.Spacer(),
          pw.Divider(color: PdfColors.grey300),
          pw.Text(
            'Thank you for using FarmTap. Questions about this document: ${brand.phone}. '
            'This document was made by FarmTap and is valid without a handwritten signature.',
            style: small,
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    ),
  );
  return await doc.save();
}
