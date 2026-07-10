import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale_model.dart';
import '../models/product_model.dart';
import '../services/sale_service.dart';

class CartItem {
  final ProductModel product;
  final double quantity;
  final Map<String, String> customDetails;

  const CartItem({
    required this.product, 
    required this.quantity,
    this.customDetails = const {},
  });

  double get total => product.sellingPrice * quantity;

  CartItem copyWith({double? quantity, Map<String, String>? customDetails}) =>
      CartItem(
        product: product, 
        quantity: quantity ?? this.quantity,
        customDetails: customDetails ?? this.customDetails,
      );
}

class CartState {
  final List<CartItem> items;
  final double discount;
  final double amountPaid;
  final String paymentMethod;

  const CartState({
    this.items = const [],
    this.discount = 0,
    this.amountPaid = 0,
    this.paymentMethod = 'Cash',
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.total);
  double get netTotal => (subtotal - discount).clamp(0, double.infinity);
  double get change => (amountPaid - netTotal).clamp(0, double.infinity);

  CartState copyWith({
    List<CartItem>? items,
    double? discount,
    double? amountPaid,
    String? paymentMethod,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addItem(ProductModel product, {double quantity = 1, Map<String, String> customDetails = const {}}) {
    final items = [...state.items];
    // We check customDetails equality as well, so same product with different custom details forms a new cart item.
    final idx = items.indexWhere((i) => i.product.id == product.id && _mapEquals(i.customDetails, customDetails));
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + quantity);
    } else {
      items.add(CartItem(product: product, quantity: quantity, customDetails: customDetails));
    }
    state = state.copyWith(items: items);
  }

  bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (a[k] != b[k]) return false;
    }
    return true;
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final items = [...state.items];
    final idx = items.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: quantity);
      state = state.copyWith(items: items);
    }
  }

  void setDiscount(double discount) =>
      state = state.copyWith(discount: discount);
  void setAmountPaid(double amount) =>
      state = state.copyWith(amountPaid: amount);
  void setPaymentMethod(String method) =>
      state = state.copyWith(paymentMethod: method);

  void clear() => state = const CartState();

  Future<SaleModel?> checkout({
    required String soldBy, 
    String orderStatus = 'Completed',
    DateTime? estimatedDelivery,
  }) async {
    if (state.items.isEmpty) return null;
    final saleItems = state.items
        .map((i) => SaleItemModel(
              productId: i.product.id,
              productName: i.product.name,
              quantity: i.quantity,
              unitPrice: i.product.sellingPrice,
              unit: i.product.unit,
              customDetails: i.customDetails,
            ))
        .toList();

    final sale = await SaleService.completeSale(
      items: saleItems,
      discount: state.discount,
      amountPaid: state.amountPaid,
      soldBy: soldBy,
      paymentMethod: state.paymentMethod,
      orderStatus: orderStatus,
      estimatedDelivery: estimatedDelivery,
    );
    clear();
    return sale;
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

// ── Sales list provider ──────────────────────────────────────────────────────

class SalesNotifier extends Notifier<List<SaleModel>> {
  @override
  List<SaleModel> build() => SaleService.getAllSales();

  void reload() => state = SaleService.getAllSales();
}

final salesProvider =
    NotifierProvider<SalesNotifier, List<SaleModel>>(SalesNotifier.new);
