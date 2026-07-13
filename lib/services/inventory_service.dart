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
        
        ('Flex Roll (3ft)', 'Flex', 10.0, 15.0, 450.0, 'sqft', 20.0, <String>[]),
        ('Flex Roll (4ft)', 'Flex', 13.0, 20.0, 600.0, 'sqft', 20.0, <String>[]),
        ('Flex Roll (5ft)', 'Flex', 15.0, 25.0, 750.0, 'sqft', 20.0, <String>[]),

        ('Wedding Cards', 'Cards', 10.0, 20.0, 500.0, 'items', 100.0, <String>[]),
        ('Visiting Cards', 'Cards', 2.0, 3.0, 1000.0, 'items', 100.0, <String>[]),
        
        ('Mug Printing', 'Merch', 150.0, 250.0, 50.0, 'items', 10.0, <String>[]),
        ('Shirts Printing', 'Merch', 300.0, 500.0, 50.0, 'items', 10.0, <String>[]),
        
        ('Photo Frames', 'Gifts', 100.0, 200.0, 30.0, 'items', 5.0, <String>[]),
        ('Photos (Passport)', 'Printing', 10.0, 20.0, 500.0, 'items', 50.0, <String>[]),
        
        ('Movies Making', 'Services', 1000.0, 2000.0, 99.0, 'jobs', 0.0, <String>[]),
        ('Bike Lamination', 'Services', 200.0, 300.0, 20.0, 'jobs', 5.0, <String>[]),
        ('Number Plates', 'Services', 300.0, 500.0, 20.0, 'items', 5.0, <String>[]),
        
        ('Spiral Binding', 'Binding', 30.0, 50.0, 50.0, 'items', 10.0, <String>[]),
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
