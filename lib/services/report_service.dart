import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/sale_model.dart';
import 'sale_service.dart';
import 'inventory_service.dart';
import 'pdf_service.dart';

class ProductReportData {
  final String productId;
  final String productName;
  final double quantitySold;
  final double currentStock;
  final double totalCost;
  final double totalRevenue;
  final String unit;

  double get profit => totalRevenue - totalCost;

  ProductReportData({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.currentStock,
    required this.totalCost,
    required this.totalRevenue,
    required this.unit,
  });
}

class MonthlyReportData {
  final DateTime month;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final int totalTransactions;
  final List<ProductReportData> productReports;
  final List<SaleModel> sales;

  MonthlyReportData({
    required this.month,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.totalTransactions,
    required this.productReports,
    required this.sales,
  });
}

class ReportService {
  static MonthlyReportData generateMonthlyReportData(int year, int month) {
    final sales = SaleService.getSalesForMonth(year, month);
    
    double totalRevenue = 0;
    double totalCost = 0;
    
    // Map to aggregate data by productId
    final Map<String, ProductReportData> aggregatedData = {};

    for (final sale in sales) {
      totalRevenue += sale.netAmount;
      
      for (final item in sale.items) {
        final product = InventoryService.getAllProducts().where((p) => p.id == item.productId || p.name == item.productName).firstOrNull;
        
        final currentCost = product?.costPrice ?? 0.0;
        final currentStock = product?.stockQuantity ?? 0.0;
        
        final itemCost = currentCost * item.quantity;
        final itemRevenue = item.total;
        
        totalCost += itemCost;

        if (aggregatedData.containsKey(item.productId)) {
          final existing = aggregatedData[item.productId]!;
          aggregatedData[item.productId] = ProductReportData(
            productId: existing.productId,
            productName: existing.productName,
            quantitySold: existing.quantitySold + item.quantity,
            currentStock: currentStock,
            totalCost: existing.totalCost + itemCost,
            totalRevenue: existing.totalRevenue + itemRevenue,
            unit: existing.unit,
          );
        } else {
          aggregatedData[item.productId] = ProductReportData(
            productId: item.productId,
            productName: item.productName,
            quantitySold: item.quantity,
            currentStock: currentStock,
            totalCost: itemCost,
            totalRevenue: itemRevenue,
            unit: item.unit,
          );
        }
      }
    }
    
    final productReports = aggregatedData.values.toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    return MonthlyReportData(
      month: DateTime(year, month),
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      totalProfit: totalRevenue - totalCost,
      totalTransactions: sales.length,
      productReports: productReports,
      sales: sales,
    );
  }

  static Future<void> autoGeneratePreviousMonthReportIfNeeded() async {
    try {
      final box = await Hive.openBox('settings');
      final now = DateTime.now();
      
      var prevMonth = now.month - 1;
      var prevYear = now.year;
      if (prevMonth == 0) {
        prevMonth = 12;
        prevYear -= 1;
      }
      
      final lastReportKey = 'last_report_${prevYear}_$prevMonth';
      final hasGenerated = box.get(lastReportKey, defaultValue: false) as bool;
      
      if (!hasGenerated) {
        final reportData = generateMonthlyReportData(prevYear, prevMonth);
        
        final pdfBytes = await PdfService.buildMonthlyReportPdfBytes(reportData);
        
        final directory = await getApplicationDocumentsDirectory();
        final reportsDir = Directory('${directory.path}/InventoryManData/Reports');
        if (!await reportsDir.exists()) {
          await reportsDir.create(recursive: true);
        }
        
        final monthStr = DateFormat('MMMM_yyyy').format(reportData.month);
        final file = File('${reportsDir.path}/Monthly_Report_$monthStr.pdf');
        
        await file.writeAsBytes(pdfBytes);
        
        await box.put(lastReportKey, true);
        debugPrint('Auto-generated monthly report at: ${file.path}');
      }
    } catch (e) {
      debugPrint('Error auto-generating monthly report: $e');
    }
  }
}
