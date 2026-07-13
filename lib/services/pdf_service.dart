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

  // ─────────────────────────────────────────────────────────────────
  //  THERMAL RECEIPT (80 mm portrait – fits standard thermal printers)
  // ─────────────────────────────────────────────────────────────────
  static Future<void> printReceipt(SaleModel sale) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontItalic = await PdfGoogleFonts.nunitoItalic();

    const primaryRed = PdfColor.fromInt(0xffd32f2f);
    const darkRed = PdfColor.fromInt(0xffb71c1c);

    // 80 mm roll — standard thermal printer width
    final format = PdfPageFormat(
      80 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 6 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── SHOP HEADER ──────────────────────────────────────────
            pw.Center(
              child: pw.Column(
                children: [
                  pw.RichText(
                    text: pw.TextSpan(
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 22,
                        fontStyle: pw.FontStyle.italic,
                      ),
                      children: [
                        pw.TextSpan(text: 'Shehr', style: const pw.TextStyle(color: PdfColors.black)),
                        pw.TextSpan(text: 'Yar', style: pw.TextStyle(color: primaryRed)),
                      ],
                    ),
                  ),
                  pw.Text(
                    'FLEX PRINTER',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 11,
                      color: primaryRed,
                      letterSpacing: 2.0,
                    ),
                  ),
                  pw.Text(
                    'Your Design, Our Precision!',
                    style: pw.TextStyle(
                      font: fontItalic,
                      fontSize: 9,
                      color: primaryRed,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Bonga Hayat Road, Sikandar Chowk',
                    style: pw.TextStyle(font: font, fontSize: 7, color: darkRed),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    '0300-1122826 | 0311-1122826',
                    style: pw.TextStyle(font: fontBold, fontSize: 7, color: primaryRed),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 6),
            pw.Divider(color: primaryRed, thickness: 1.5),
            pw.SizedBox(height: 4),

            // ── ORDER INFO ────────────────────────────────────────────
            _thermalRow(font, fontBold, 'Order #', sale.orderNumber, primaryRed),
            _thermalRow(font, fontBold, 'Date', DateFormat('dd/MM/yyyy').format(sale.saleDate), primaryRed),
            if (sale.customerName.isNotEmpty)
              _thermalRow(font, fontBold, 'Customer', sale.customerName, primaryRed),
            if (sale.customerPhone.isNotEmpty)
              _thermalRow(font, fontBold, 'Cell', sale.customerPhone, primaryRed),
            if (sale.estimatedDelivery != null)
              _thermalRow(
                font, fontBold, 'Delivery',
                DateFormat('dd/MM/yyyy hh:mm a').format(sale.estimatedDelivery!),
                darkRed,
              ),

            pw.SizedBox(height: 6),
            pw.Divider(color: primaryRed, thickness: 1),

            // ── TABLE HEADER ──────────────────────────────────────────
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.black, width: 1.0),
                  bottom: pw.BorderSide(color: PdfColors.black, width: 1.0),
                ),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 4, child: pw.Text('Item / File', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
                  pw.SizedBox(width: 4),
                  pw.SizedBox(width: 28, child: pw.Text('Qty', style: pw.TextStyle(font: fontBold, fontSize: 7.5), textAlign: pw.TextAlign.right)),
                  pw.SizedBox(width: 4),
                  pw.SizedBox(width: 32, child: pw.Text('Rate', style: pw.TextStyle(font: fontBold, fontSize: 7.5), textAlign: pw.TextAlign.right)),
                  pw.SizedBox(width: 4),
                  pw.SizedBox(width: 34, child: pw.Text('Amt', style: pw.TextStyle(font: fontBold, fontSize: 7.5), textAlign: pw.TextAlign.right)),
                ],
              ),
            ),

            // ── SALE ITEMS ────────────────────────────────────────────
            ...sale.items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final fileName = item.customDetails['Details'] ?? item.productName;
              final size = item.customDetails['Size'] ?? '';
              final sqrFt = item.customDetails['Sqr ft'] ?? '';

              return pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Item name row
                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            '${idx + 1}. $fileName',
                            style: pw.TextStyle(font: fontBold, fontSize: 7.5),
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.SizedBox(
                          width: 28,
                          child: pw.Text(
                            item.quantity.toStringAsFixed(isFlex(item) ? 1 : 0),
                            style: pw.TextStyle(font: font, fontSize: 7),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.SizedBox(
                          width: 32,
                          child: pw.Text(
                            item.unitPrice.toStringAsFixed(0),
                            style: pw.TextStyle(font: font, fontSize: 7),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.SizedBox(
                          width: 34,
                          child: pw.Text(
                            item.total.toStringAsFixed(0),
                            style: pw.TextStyle(font: fontBold, fontSize: 7.5),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    // Size / SqrFt details
                    if (size.isNotEmpty || sqrFt.isNotEmpty)
                      pw.Text(
                        [if (size.isNotEmpty) 'Size: $size', if (sqrFt.isNotEmpty) 'Sqft: $sqrFt'].join('  |  '),
                        style: pw.TextStyle(font: fontItalic, fontSize: 6.5, color: PdfColors.grey700),
                      ),
                  ],
                ),
              );
            }),

            pw.Divider(color: primaryRed, thickness: 1),
            pw.SizedBox(height: 4),

            // ── TOTALS ────────────────────────────────────────────────
            _totalRow(font, fontBold, 'Subtotal', _fmt.format(sale.totalAmount), primaryRed, false),
            if ((sale.discount) > 0)
              _totalRow(font, fontBold, 'Discount', '- ${_fmt.format(sale.discount)}', primaryRed, false),
            pw.Divider(color: primaryRed, thickness: 0.5),
            _totalRow(font, fontBold, 'TOTAL', 'PKR ${_fmt.format(sale.netAmount)}', primaryRed, true),
            pw.SizedBox(height: 3),
            _totalRow(font, fontBold, 'Advance Paid', 'PKR ${_fmt.format(sale.amountPaid)}', PdfColors.green800, false),
            _totalRow(
              font, fontBold, 'Balance Due',
              'PKR ${_fmt.format((sale.netAmount - sale.amountPaid).abs())}',
              darkRed, true,
            ),

            pw.SizedBox(height: 8),
            pw.Divider(color: primaryRed, thickness: 1),
            pw.SizedBox(height: 4),

            // ── FOOTER SERVICES ───────────────────────────────────────
            pw.Center(
              child: pw.Text(
                'SERVICES',
                style: pw.TextStyle(font: fontBold, fontSize: 8, color: primaryRed, letterSpacing: 1.5),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                'Flex • Wedding Cards • Visiting Cards\nMug Print • Shirt Print • Photo Frame\nPVC Card • Bike Lamination • Number Plate',
                style: pw.TextStyle(font: font, fontSize: 6.5, color: darkRed),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                '"Big Prints – Bold Impact"',
                style: pw.TextStyle(font: fontItalic, fontSize: 7, color: primaryRed),
              ),
            ),
            pw.SizedBox(height: 3),

            pw.Divider(color: primaryRed, thickness: 0.5),
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(font: fontBold, fontSize: 8, color: primaryRed),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                'M. ShehrYar – CEO',
                style: pw.TextStyle(font: fontItalic, fontSize: 7, color: darkRed),
              ),
            ),
            pw.SizedBox(height: 4),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'Receipt_${sale.orderNumber}',
    );
  }

  // Helper: single label-value row for order info
  static pw.Widget _thermalRow(
    pw.Font font, pw.Font fontBold, String label, String value, PdfColor color,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$label:', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: color)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 7.5)),
        ],
      ),
    );
  }

  // Helper: total rows at the bottom
  static pw.Widget _totalRow(
    pw.Font font, pw.Font fontBold, String label, String value, PdfColor color, bool bold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: bold ? fontBold : font, fontSize: bold ? 9 : 8, color: color)),
          pw.Text(value, style: pw.TextStyle(font: bold ? fontBold : font, fontSize: bold ? 9 : 8, color: color)),
        ],
      ),
    );
  }


  // ─────────────────────────────────────────────────────────────────
  //  MONTHLY REPORT PDF
  // ─────────────────────────────────────────────────────────────────
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
              pw.RichText(
                text: pw.TextSpan(
                  style: pw.TextStyle(font: fontBold, fontSize: 20, fontStyle: pw.FontStyle.italic),
                  children: [
                    pw.TextSpan(text: 'Shehr', style: const pw.TextStyle(color: PdfColors.black)),
                    pw.TextSpan(text: 'Yar ', style: const pw.TextStyle(color: PdfColor.fromInt(0xFFD32F2F))),
                    pw.TextSpan(text: 'FLEX PRINTER', style: const pw.TextStyle(color: PdfColor.fromInt(0xFFD32F2F), fontSize: 12)),
                  ],
                ),
              ),
              pw.Text('Your Design, Our Precision!', style: pw.TextStyle(font: fontItalic, fontSize: 10, color: const PdfColor.fromInt(0xFFD32F2F))),
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
            pw.Text(
              'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(font: fontItalic, fontSize: 9, color: PdfColors.grey500),
            ),
            pw.Text(
              'ShehrYar Flex Printer - Confidential',
              style: pw.TextStyle(font: fontItalic, fontSize: 9, color: PdfColors.grey500),
            ),
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
          color: PdfColors.red50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: PdfColors.red100),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.red900)),
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

  // ─────────────────────────────────────────────────────────────────
  //  PRODUCT SAMPLE / BROCHURE PDF
  // ─────────────────────────────────────────────────────────────────
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
            gradient: const pw.LinearGradient(colors: [PdfColors.red900, PdfColors.red700]),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(product.name, style: pw.TextStyle(font: fontBold, fontSize: 26, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text(product.category, style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.red100)),
              ]),
              pw.RichText(
                text: pw.TextSpan(
                  style: pw.TextStyle(font: fontBold, fontSize: 16, fontStyle: pw.FontStyle.italic),
                  children: [
                    pw.TextSpan(text: 'Shehr', style: const pw.TextStyle(color: PdfColors.white)),
                    pw.TextSpan(text: 'Yar ', style: const pw.TextStyle(color: PdfColors.white)),
                    pw.TextSpan(text: 'FLEX PRINTER', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 24),

        // Pricing
        pw.Row(children: [
          pw.Expanded(child: pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.green200),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Selling Price', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text('PKR ${_fmt.format(product.sellingPrice)}', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.green900)),
            ]),
          )),
          pw.SizedBox(width: 12),
          pw.Expanded(child: pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.red200),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Unit', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text(product.unit, style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.red900)),
            ]),
          )),
        ]),
        pw.SizedBox(height: 20),

        if (product.description.isNotEmpty) ...[
          pw.Text('Description', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
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
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                border: pw.Border.all(color: PdfColors.red200),
              ),
              child: pw.Text(f, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.red800)),
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

  static bool isFlex(SaleItemModel item) =>
      item.customDetails.containsKey('Sqr ft') || item.customDetails.containsKey('Size');
}
