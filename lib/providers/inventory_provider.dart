import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../services/inventory_service.dart';

class InventoryNotifier extends Notifier<List<ProductModel>> {
  @override
  List<ProductModel> build() => InventoryService.getAllProducts();

  void reload() {
    state = InventoryService.getAllProducts();
  }

  Future<void> addProduct({
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
    await InventoryService.addProduct(
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
    );
    reload();
  }

  Future<void> updateProduct(ProductModel product) async {
    await InventoryService.updateProduct(product);
    reload();
  }

  Future<void> deleteProduct(String productId) async {
    await InventoryService.deleteProduct(productId);
    reload();
  }

  Future<void> updateStock(String productId, double quantity) async {
    await InventoryService.updateStock(productId, quantity);
    reload();
  }

  List<ProductModel> get lowStockItems =>
      state.where((p) => p.isLowStock).toList();
}

final inventoryProvider =
    NotifierProvider<InventoryNotifier, List<ProductModel>>(InventoryNotifier.new);

final categoriesProvider = Provider<List<String>>((ref) {
  ref.watch(inventoryProvider);
  return InventoryService.getCategories();
});
