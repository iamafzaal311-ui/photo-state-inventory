import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale_model.dart';
import '../models/product_model.dart';
import 'report_service.dart';

class PdfService {
  static final _fmt = NumberFormat('#,##0.00');

  static Future<void> printReceipt(SaleModel sale) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      margin: const pw.EdgeInsets.all(12),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Center(child: pw.Column(children: [
            pw.Text('PrintPOS Pro', style: pw.TextStyle(font: fontBold, fontSize: 18)),
            pw.SizedBox(height: 4),
            pw.Text('Printing & Photostat Shop', style: pw.TextStyle(font: font, fontSize: 10)),
            pw.SizedBox(height: 2),
            pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate),
              style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
          ])),
          pw.Text('Order: ${sale.orderNumber}', style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 6),
          // Items
          ...sale.items.map((item) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(item.productName, style: pw.TextStyle(font: font, fontSize: 11)),
                  pw.Text('${item.quantity.toStringAsFixed(0)} ${item.unit} × PKR ${item.unitPrice.toStringAsFixed(0)}',
                    style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                  if (item.customDetails.isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: item.customDetails.entries.map((e) => 
                        pw.Text('- ${e.key}: ${e.value}', style: pw.TextStyle(font: font, fontSize: 8, fontStyle: pw.FontStyle.italic))
                      ).toList(),
                    ),
                ])),
                pw.Text('PKR ${_fmt.format(item.total)}', style: pw.TextStyle(font: fontBold, fontSize: 11)),
              ],
            ),
          )),
          pw.SizedBox(height: 6),
          pw.Divider(),
          if (sale.discount > 0) ...[
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Discount:', style: pw.TextStyle(font: font, fontSize: 11)),
                pw.Text('- PKR ${_fmt.format(sale.discount)}', style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.red)),
              ],
            ),
          ],
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL:', style: pw.TextStyle(font: fontBold, fontSize: 13)),
              pw.Text('PKR ${_fmt.format(sale.netAmount)}', style: pw.TextStyle(font: fontBold, fontSize: 13)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Paid (${sale.paymentMethod}):', style: pw.TextStyle(font: font, fontSize: 11)),
              pw.Text('PKR ${_fmt.format(sale.amountPaid)}', style: pw.TextStyle(font: font, fontSize: 11)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Change:', style: pw.TextStyle(font: font, fontSize: 11)),
              pw.Text('PKR ${_fmt.format(sale.change)}', style: pw.TextStyle(font: font, fontSize: 11)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Center(child: pw.Column(children: [
            pw.Text('Served by: ${sale.soldBy}', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text('Thank you! Please visit again.', style: pw.TextStyle(font: fontBold, fontSize: 11)),
            pw.SizedBox(height: 4),
            pw.Text('Receipt #${sale.id.substring(0, 8).toUpperCase()}',
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500)),
          ])),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (_) => pdf.save(), name: 'Receipt_${sale.id.substring(0, 8)}');
  }

  static Future<Uint8List> buildMonthlyReportPdfBytes(MonthlyReportData data) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontItalic = await PdfGoogleFonts.nunitoItalic();

    // Compute daily totals
    final Map<int, double> dailyMap = {};
    for (final s in data.sales) {
      dailyMap[s.saleDate.day] = (dailyMap[s.saleDate.day] ?? 0) + s.netAmount;
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('PrintPOS Pro', style: pw.TextStyle(font: fontBold, fontSize: 18)),
              pw.Text('Printing & Photostat Shop', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('MONTHLY SALES REPORT', style: pw.TextStyle(font: fontBold, fontSize: 14)),
              pw.Text(DateFormat('MMMM yyyy').format(data.month), style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
            ]),
          ],
        ),
      ),
      footer: (_) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(font: fontItalic, fontSize: 9, color: PdfColors.grey500)),
            pw.Text('PrintPOS Pro - Confidential',
              style: pw.TextStyle(font: fontItalic, fontSize: 9, color: PdfColors.grey500)),
          ],
        ),
      ),
      build: (context) => [
        pw.SizedBox(height: 24),
        // Summary cards row
        pw.Row(children: [
          _pdfStatBox(font, fontBold, 'Total Revenue', 'PKR ${_fmt.format(data.totalRevenue)}'),
          pw.SizedBox(width: 12),
          _pdfStatBox(font, fontBold, 'Total Profit', 'PKR ${_fmt.format(data.totalProfit)}'),
          pw.SizedBox(width: 12),
          _pdfStatBox(font, fontBold, 'Transactions', '${data.totalTransactions}'),
        ]),
        pw.SizedBox(height: 24),
        // Product-wise Sales & Profit Analysis
        if (data.productReports.isNotEmpty) ...[
          pw.Text('Product-wise Sales & Profit Analysis', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfCell('Product / Item', fontBold),
                  _pdfCell('Sold', fontBold, align: pw.Alignment.centerRight),
                  _pdfCell('In Stock', fontBold, align: pw.Alignment.centerRight),
                  _pdfCell('Cost (PKR)', fontBold, align: pw.Alignment.centerRight),
                  _pdfCell('Revenue (PKR)', fontBold, align: pw.Alignment.centerRight),
                  _pdfCell('Profit (PKR)', fontBold, align: pw.Alignment.centerRight),
                ],
              ),
              ...data.productReports.map((p) => pw.TableRow(children: [
                _pdfCell(p.productName, font),
                _pdfCell('${p.quantitySold.toStringAsFixed(0)} ${p.unit}', font, align: pw.Alignment.centerRight),
                _pdfCell('${p.currentStock.toStringAsFixed(0)} ${p.unit}', font, align: pw.Alignment.centerRight),
                _pdfCell(_fmt.format(p.totalCost), font, align: pw.Alignment.centerRight),
                _pdfCell(_fmt.format(p.totalRevenue), font, align: pw.Alignment.centerRight),
                _pdfCell(_fmt.format(p.profit), fontBold, align: pw.Alignment.centerRight),
              ])),
            ],
          ),
          pw.SizedBox(height: 24),
        ],
        // Daily breakdown table
        pw.Text('Daily Revenue Breakdown', style: pw.TextStyle(font: fontBold, fontSize: 14)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _pdfCell('Day', fontBold, align: pw.Alignment.center),
                _pdfCell('Date', fontBold),
                _pdfCell('Revenue (PKR)', fontBold, align: pw.Alignment.centerRight),
              ],
            ),
            ...(dailyMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
              .map((e) => pw.TableRow(children: [
              _pdfCell('${e.key}', font, align: pw.Alignment.center),
              _pdfCell(DateFormat('dd MMM yyyy').format(DateTime(data.month.year, data.month.month, e.key)), font),
              _pdfCell('PKR ${_fmt.format(e.value)}', fontBold, align: pw.Alignment.centerRight),
            ])),
          ],
        ),
      ],
    ));

    return pdf.save();
  }

  static Future<void> generateMonthlyReport(MonthlyReportData data) async {
    await Printing.layoutPdf(
      onLayout: (_) => buildMonthlyReportPdfBytes(data),
      name: 'Monthly_Report_${DateFormat('MMMM_yyyy').format(data.month)}',
    );
  }

  static pw.Widget _pdfStatBox(pw.Font font, pw.Font fontBold, String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.indigo50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: PdfColors.indigo100),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.indigo900)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
        ]),
      ),
    );
  }

  static pw.Widget _pdfCell(String text, pw.Font font, {pw.Alignment? align}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Align(
        alignment: align ?? pw.Alignment.centerLeft,
        child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10)),
      ),
    );
  }

  static Future<void> generateProductSamplePdf(ProductModel product) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    final List<pw.MemoryImage> images = [];
    for (final path in product.sampleImages) {
      try {
        final bytes = await File(path).readAsBytes();
        images.add(pw.MemoryImage(bytes));
      } catch (_) {}
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        // Header
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            gradient: const pw.LinearGradient(colors: [PdfColors.indigo800, PdfColors.indigo600]),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(product.name, style: pw.TextStyle(font: fontBold, fontSize: 26, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text(product.category, style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.indigo200)),
              ]),
              pw.Text('PrintPOS Pro', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.white)),
            ],
          ),
        ),
        pw.SizedBox(height: 24),

        // Pricing
        pw.Row(children: [
          pw.Expanded(child: pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(color: PdfColors.green50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: PdfColors.green200)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Selling Price', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text('PKR ${_fmt.format(product.sellingPrice)}', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.green900)),
            ]),
          )),
          pw.SizedBox(width: 12),
          pw.Expanded(child: pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(color: PdfColors.indigo50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)), border: pw.Border.all(color: PdfColors.indigo200)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Unit', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text(product.unit, style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.indigo900)),
            ]),
          )),
        ]),
        pw.SizedBox(height: 20),

        if (product.description.isNotEmpty) ...[
          pw.Text('Description', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Text(product.description, style: pw.TextStyle(font: font, fontSize: 11, lineSpacing: 4)),
          ),
          pw.SizedBox(height: 20),
        ],

        if (product.customFields.isNotEmpty) ...[
          pw.Text('Customizable Options', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 8, runSpacing: 8,
            children: product.customFields.map((f) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: pw.BoxDecoration(color: PdfColors.indigo50, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)), border: pw.Border.all(color: PdfColors.indigo200)),
              child: pw.Text(f, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.indigo800)),
            )).toList(),
          ),
          pw.SizedBox(height: 20),
        ],

        if (images.isNotEmpty) ...[
          pw.Text('Sample Gallery', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 12, runSpacing: 12,
            children: images.map((img) => pw.Container(
              width: 180, height: 180,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                image: pw.DecorationImage(image: img, fit: pw.BoxFit.cover),
              ),
            )).toList(),
          ),
        ],
      ],
    ));

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${product.name}_Brochure.pdf',
    );
  }
}
