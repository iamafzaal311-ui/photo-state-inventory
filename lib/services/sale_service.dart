import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/sale_model.dart';
import 'inventory_service.dart';

class SaleService {
  static const String _boxName = 'sales';
  static const uuid = Uuid();

  static Box<SaleModel> get _box => Hive.box<SaleModel>(_boxName);

  static Future<SaleModel> completeSale({
    required List<SaleItemModel> items,
    required double discount,
    required double amountPaid,
    required String soldBy,
    required String paymentMethod,
    String notes = '',
    String orderStatus = 'Completed',
    DateTime? estimatedDelivery,
  }) async {
    final total = items.fold(0.0, (sum, item) => sum + item.total);
    final now = DateTime.now();
    // Generate an order number like ORD-YYYYMMDD-XXXX
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomPart = uuid.v4().substring(0, 4).toUpperCase();
    final orderNum = 'ORD-$dateStr-$randomPart';
    final sale = SaleModel(
      id: uuid.v4(),
      items: items,
      totalAmount: total,
      discount: discount,
      amountPaid: amountPaid,
      saleDate: now,
      soldBy: soldBy,
      paymentMethod: paymentMethod,
      notes: notes,
      orderNumber: orderNum,
      orderStatus: orderStatus,
      estimatedDelivery: estimatedDelivery,
    );
    await _box.put(sale.id, sale);

    // Deduct stock
    for (final item in items) {
      await InventoryService.deductStock(item.productId, item.quantity);
    }
    return sale;
  }

  static List<SaleModel> getAllSales() => _box.values.toList()
    ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

  static List<SaleModel> getSalesForDate(DateTime date) {
    return _box.values.where((s) {
      return s.saleDate.year == date.year &&
          s.saleDate.month == date.month &&
          s.saleDate.day == date.day;
    }).toList()
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
  }

  static List<SaleModel> getSalesForMonth(int year, int month) {
    return _box.values
        .where((s) => s.saleDate.year == year && s.saleDate.month == month)
        .toList()
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
  }

  static double getTodayRevenue() {
    final today = DateTime.now();
    return getSalesForDate(today)
        .fold(0.0, (sum, s) => sum + s.netAmount);
  }

  static int getTodayTransactionCount() {
    return getSalesForDate(DateTime.now()).length;
  }

  static double getMonthRevenue(int year, int month) {
    return getSalesForMonth(year, month)
        .fold(0.0, (sum, s) => sum + s.netAmount);
  }

  static Map<String, double> getDailySalesForMonth(int year, int month) {
    final sales = getSalesForMonth(year, month);
    final Map<String, double> dailyMap = {};
    for (final sale in sales) {
      final key = '${sale.saleDate.day}';
      dailyMap[key] = (dailyMap[key] ?? 0) + sale.netAmount;
    }
    return dailyMap;
  }

  static Map<String, double> getCategorySalesForMonth(int year, int month) {
    final sales = getSalesForMonth(year, month);
    final Map<String, double> categoryMap = {};
    for (final sale in sales) {
      for (final item in sale.items) {
        categoryMap[item.productName] =
            (categoryMap[item.productName] ?? 0) + item.total;
      }
    }
    return categoryMap;
  }
}
