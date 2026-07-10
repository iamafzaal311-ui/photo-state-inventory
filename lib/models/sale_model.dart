import 'package:hive/hive.dart';

part 'sale_model.g.dart';

@HiveType(typeId: 2)
class SaleItemModel extends HiveObject {
  @HiveField(0)
  late String productId;

  @HiveField(1)
  late String productName;

  @HiveField(2)
  late double quantity;

  @HiveField(3)
  late double unitPrice;

  @HiveField(4)
  late String unit;

  @HiveField(5)
  late Map<String, String> customDetails;

  double get total => quantity * unitPrice;

  SaleItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unit,
    this.customDetails = const {},
  });
}

@HiveType(typeId: 3)
class SaleModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late List<SaleItemModel> items;

  @HiveField(2)
  late double totalAmount;

  @HiveField(3)
  late double discount;

  @HiveField(4)
  late double amountPaid;

  @HiveField(5)
  late DateTime saleDate;

  @HiveField(6)
  late String soldBy;

  @HiveField(7)
  late String paymentMethod; // cash, card, upi

  @HiveField(8)
  late String notes;

  @HiveField(9)
  late String orderNumber;

  @HiveField(10)
  late String orderStatus; // Pending, In Progress, Ready, Delivered, Cancelled

  @HiveField(11)
  late DateTime? estimatedDelivery;

  double get change => amountPaid - (totalAmount - discount);
  double get netAmount => totalAmount - discount;

  SaleModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.discount,
    required this.amountPaid,
    required this.saleDate,
    required this.soldBy,
    required this.paymentMethod,
    this.notes = '',
    this.orderNumber = '',
    this.orderStatus = 'Completed',
    this.estimatedDelivery,
  });
}
