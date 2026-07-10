import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 1)
class ProductModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String category;

  @HiveField(3)
  late double costPrice;

  @HiveField(4)
  late double sellingPrice;

  @HiveField(5)
  late double stockQuantity;

  @HiveField(6)
  late String unit; // pages, reams, items, sheets

  @HiveField(7)
  late double lowStockThreshold;

  @HiveField(8)
  late DateTime createdAt;

  @HiveField(9)
  late DateTime updatedAt;

  @HiveField(10)
  late String description;

  @HiveField(11)
  late List<String> sampleImages;

  @HiveField(12)
  late List<String> customFields;

  bool get isLowStock => stockQuantity <= lowStockThreshold;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.unit,
    required this.lowStockThreshold,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.sampleImages = const [],
    this.customFields = const [],
  });
}
