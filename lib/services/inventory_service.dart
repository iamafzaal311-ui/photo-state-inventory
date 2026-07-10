import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';

class InventoryService {
  static const String _boxName = 'products';
  static const uuid = Uuid();

  static Box<ProductModel> get _box => Hive.box<ProductModel>(_boxName);

  static Future<void> seedDefaultProducts() async {
    if (_box.isEmpty) {
      final defaults = [
        ('B/W Copy', 'Copying', 1.5, 2.0, 1000.0, 'pages', 200.0, <String>[]),
        ('Color Copy', 'Copying', 5.0, 8.0, 500.0, 'pages', 100.0, <String>[]),
        ('Scanning', 'Scanning', 3.0, 5.0, 999.0, 'pages', 0.0, <String>[]),
        ('Flex Printing', 'Printing', 10.0, 15.0, 1000.0, 'sq-ft', 100.0, ['Title/Subject', 'Name on Flex', 'Length (ft)', 'Width (ft)']),
        ('Shirts Printing', 'Merch', 300.0, 500.0, 50.0, 'items', 10.0, ['Text/Name to Print', 'Size', 'Color']),
        ('Mug Printing', 'Merch', 150.0, 250.0, 50.0, 'items', 10.0, ['Text to Print', 'Photo Theme']),
        ('Photo Frames', 'Gifts', 100.0, 200.0, 30.0, 'items', 5.0, ['Frame Size', 'Orientation']),
        ('Visiting Cards', 'Cards', 2.0, 3.0, 1000.0, 'items', 100.0, ['Company Name', 'Person Name', 'Contact Info']),
        ('Wedding Cards', 'Cards', 10.0, 20.0, 500.0, 'items', 100.0, ['Bride & Groom Names', 'Event Date', 'Venue']),
        ('PVC Card Copies', 'Printing', 30.0, 50.0, 100.0, 'items', 20.0, ['Employee/Student Name', 'ID/Designation']),
        ('Photos', 'Printing', 10.0, 20.0, 500.0, 'items', 50.0, ['Size (e.g. Passport)', 'Background Color']),
        ('Movies Making', 'Services', 1000.0, 2000.0, 99.0, 'jobs', 0.0, ['Event Type', 'Duration', 'Song Details']),
        ('Tonner Filler', 'Services', 200.0, 400.0, 50.0, 'items', 5.0, ['Printer Model']),
        ('Number Plates', 'Services', 300.0, 500.0, 20.0, 'items', 5.0, ['Vehicle Number', 'Style']),
        ('Bike Lamination', 'Services', 200.0, 300.0, 20.0, 'jobs', 5.0, ['Bike Model', 'Lamination Type']),
        ('Taping', 'Services', 50.0, 100.0, 50.0, 'jobs', 10.0, ['Details']),
        ('Spiral Binding', 'Binding', 30.0, 50.0, 50.0, 'items', 10.0, <String>[]),
        ('Hard Binding', 'Binding', 80.0, 150.0, 20.0, 'items', 5.0, <String>[]),
        ('Lamination A4', 'Lamination', 10.0, 20.0, 100.0, 'items', 20.0, <String>[]),
        ('A4 Paper Ream', 'Paper', 400.0, 500.0, 20.0, 'reams', 5.0, <String>[]),
      ];
      for (final d in defaults) {
        final p = ProductModel(
          id: uuid.v4(),
          name: d.$1,
          category: d.$2,
          costPrice: d.$3,
          sellingPrice: d.$4,
          stockQuantity: d.$5,
          unit: d.$6,
          lowStockThreshold: d.$7,
          customFields: d.$8,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _box.put(p.id, p);
      }
    }
  }

  static List<ProductModel> getAllProducts() => _box.values.toList();

  static List<ProductModel> getByCategory(String category) =>
      _box.values.where((p) => p.category == category).toList();

  static List<ProductModel> getLowStockProducts() =>
      _box.values.where((p) => p.isLowStock).toList();

  static Future<ProductModel> addProduct({
    required String name,
    required String category,
    required double costPrice,
    required double sellingPrice,
    required double stockQuantity,
    required String unit,
    required double lowStockThreshold,
    String description = '',
    List<String> sampleImages = const [],
    List<String> customFields = const [],
  }) async {
    final product = ProductModel(
      id: uuid.v4(),
      name: name,
      category: category,
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      stockQuantity: stockQuantity,
      unit: unit,
      lowStockThreshold: lowStockThreshold,
      description: description,
      sampleImages: sampleImages,
      customFields: customFields,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _box.put(product.id, product);
    return product;
  }

  static Future<void> updateProduct(ProductModel product) async {
    product.updatedAt = DateTime.now();
    await product.save();
  }

  static Future<void> updateStock(String productId, double newQuantity) async {
    final p = _box.get(productId);
    if (p != null) {
      p.stockQuantity = newQuantity;
      p.updatedAt = DateTime.now();
      await p.save();
    }
  }

  static Future<void> deductStock(String productId, double quantity) async {
    final p = _box.get(productId);
    if (p != null) {
      p.stockQuantity = (p.stockQuantity - quantity).clamp(0, double.infinity);
      p.updatedAt = DateTime.now();
      await p.save();
    }
  }

  static Future<void> deleteProduct(String productId) async {
    await _box.delete(productId);
  }

  static List<String> getCategories() {
    return _box.values.map((p) => p.category).toSet().toList()..sort();
  }
}
