import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _searchProduct = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final products = ref.watch(inventoryProvider);
    final categories = ['All', ...ref.watch(categoriesProvider)];
    final auth = ref.watch(authProvider);

    final filtered = products.where((p) {
      final matchSearch = p.name.toLowerCase().contains(_searchProduct.toLowerCase());
      final matchCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          // Cart takes 300-360px, product area gets the rest
          final cartWidth = (totalWidth * 0.30).clamp(280.0, 360.0);

          return Row(
            children: [
              // Products panel (left)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Point of Sale',
                        style: Theme.of(context).textTheme.headlineLarge,
                        overflow: TextOverflow.ellipsis,
                      ).animate().fadeIn().slideY(begin: -0.1),
                      const SizedBox(height: 16),
                      // Search & category filter
                      Row(
                        children: [
                          Flexible(
                            flex: 3,
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search products...',
                                prefixIcon: Icon(Icons.search, size: 18),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (v) => setState(() => _searchProduct = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            flex: 4,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: categories.map((c) => Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: _CategoryChip(
                                    label: c,
                                    selected: _selectedCategory == c,
                                    onTap: () => setState(() => _selectedCategory = c),
                                  ),
                                )).toList(),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: (totalWidth - cartWidth) / 2 > 180 ? 200 : 160,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.05,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _ProductCard(
                            product: filtered[index],
                            onAdd: (p) => _handleAddProduct(p),
                          ).animate().fadeIn(delay: Duration(milliseconds: 30 * index)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Cart panel (right) — fixed adaptive width
              SizedBox(
                width: cartWidth,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(left: BorderSide(color: AppColors.borderColor)),
                  ),
                  child: _CartPanel(
                    cart: cart,
                    soldBy: auth.currentUser?.username ?? 'Staff',
                    onCheckout: (sale) {},
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleAddProduct(ProductModel p) async {
    final isFlex = p.category.toLowerCase().contains('flex') ||
        p.name.toLowerCase().contains('flex');

    // ── For Flex: we need to know available sqft stock ──────────────
    // stockQuantity for flex stores total sqft (Length × Width added when stocking)
    final availableSqft = p.stockQuantity;

    final details = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        final fileNameCtrl = TextEditingController();
        final widthCtrl = TextEditingController(text: '1');
        final heightCtrl = TextEditingController(text: '1');
        final qtyCtrl = TextEditingController(text: '1');
        final rateCtrl = TextEditingController(text: p.sellingPrice.toStringAsFixed(0));
        double sqrFt = 1.0;
        double total = p.sellingPrice;

        void updateCalc() {
          final w = double.tryParse(widthCtrl.text) ?? 1;
          final h = double.tryParse(heightCtrl.text) ?? 1;
          final q = double.tryParse(qtyCtrl.text) ?? 1;
          final r = double.tryParse(rateCtrl.text) ?? 0;
          sqrFt = isFlex ? (w * h * q) : 1.0;
          total = isFlex ? (w * h * q * r) : (q * r);
        }

        return StatefulBuilder(
          builder: (context, setState) {
            void onChanged(String _) => setState(() => updateCalc());
            final bool overStock = isFlex &&
                (double.tryParse(widthCtrl.text) ?? 1) *
                    (double.tryParse(heightCtrl.text) ?? 1) *
                    (double.tryParse(qtyCtrl.text) ?? 1) >
                availableSqft;

            return AlertDialog(
              title: Row(
                children: [
                  const Text('🖨️ '),
                  Expanded(
                    child: Text(
                      '${isFlex ? "Flex Order" : "Item"}: ${p.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFlex)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('📏 ', style: TextStyle(fontSize: 14)),
                            Text(
                              'Available Stock: ${availableSqft.toStringAsFixed(1)} sqft',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isFlex) const SizedBox(height: 12),
                    TextField(
                      controller: fileNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'File Name / Details (Optional)',
                        prefixIcon: Icon(Icons.description_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isFlex) ...[
                      const Text('Dimensions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: widthCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Width (ft)',
                                prefixIcon: Icon(Icons.width_normal_outlined, size: 18),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: onChanged,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('×',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                                  color: AppColors.primary)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: heightCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Height (ft)',
                                prefixIcon: Icon(Icons.height_outlined, size: 18),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: onChanged,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            decoration: const InputDecoration(
                              labelText: 'QTY / Pieces',
                              prefixIcon: Icon(Icons.tag, size: 18),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: onChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: rateCtrl,
                            decoration: InputDecoration(
                              labelText: isFlex ? 'Rate / sqft' : 'Unit Price (PKR)',
                              prefixIcon: const Icon(Icons.attach_money, size: 18),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: onChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Summary box
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: overStock
                            ? const Color(0xFFFFF3E0)
                            : AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: overStock ? AppColors.accentOrange : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (isFlex)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Sqft', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                Text(
                                  sqrFt.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: overStock ? AppColors.accentOrange : AppColors.textPrimary,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          if (isFlex) const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              Text(
                                'PKR ${total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (overStock)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.accentOrange, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Exceeds available stock (${availableSqft.toStringAsFixed(0)} sqft)',
                                    style: const TextStyle(color: AppColors.accentOrange, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: overStock ? null : () {
                    final cd = <String, String>{};
                    if (fileNameCtrl.text.isNotEmpty) cd['Details'] = fileNameCtrl.text;
                    if (isFlex) {
                      cd['Size'] = '${widthCtrl.text}x${heightCtrl.text} ft';
                      final w = double.tryParse(widthCtrl.text) ?? 1;
                      final h = double.tryParse(heightCtrl.text) ?? 1;
                      cd['sqft_per_piece'] = (w * h).toString();
                    }
                    Navigator.pop(ctx, {
                      'customDetails': cd,
                      'rate': double.tryParse(rateCtrl.text) ?? 0,
                      'qty': double.tryParse(qtyCtrl.text) ?? 1,
                      'sqft_per_piece': isFlex ? ((double.tryParse(widthCtrl.text) ?? 1) * (double.tryParse(heightCtrl.text) ?? 1)) : 1.0,
                    });
                  },
                  child: const Text('Add to Cart'),
                ),
              ],
            );
          },
        );
      },
    );

    if (details != null) {
      final rate = details['rate'] as double;
      final sqftPerPiece = details['sqft_per_piece'] as double;
      final qty = details['qty'] as double;
      final customDetails = details['customDetails'] as Map<String, String>;

      // For flex: selling price = price per piece (sqft_per_piece × rate)
      final productOverride = ProductModel(
        id: p.id,
        name: p.name,
        category: p.category,
        unit: p.unit,
        sellingPrice: isFlex ? (sqftPerPiece * rate) : rate,
        costPrice: p.costPrice,
        stockQuantity: p.stockQuantity,
        lowStockThreshold: p.lowStockThreshold,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
        description: p.description,
        sampleImages: p.sampleImages,
        customFields: p.customFields,
      );

      // Cart quantity is simply the number of pieces (qty)
      ref.read(cartProvider.notifier).addItem(
        productOverride,
        customDetails: customDetails,
        quantity: qty,
      );

      // Check if remaining stock after adding will be ≤ 20 sqft (flex low-stock alert)
      if (isFlex) {
        final totalSqftAdded = sqftPerPiece * qty;
        final remaining = p.stockQuantity - totalSqftAdded;
        if (remaining <= 20 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Text('⚠️ ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      'LOW FLEX STOCK: Only ${remaining.toStringAsFixed(1)} sqft remaining for "${p.name}"!',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.accentOrange,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 12, fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final ProductModel product;
  final ValueChanged<ProductModel> onAdd;
  const _ProductCard({required this.product, required this.onAdd});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;

  Color get _catColor {
    switch (widget.product.category) {
      case 'Copying': return AppColors.primary;
      case 'Printing': return AppColors.accent;
      case 'Binding': return AppColors.accentOrange;
      case 'Lamination': return const Color(0xFF8B5CF6);
      case 'Scanning': return AppColors.accentGreen;
      default: return AppColors.textMuted;
    }
  }

  String get _catEmoji {
    switch (widget.product.category) {
      case 'Copying': return '📄';
      case 'Printing': return '🖨️';
      case 'Binding': return '📘';
      case 'Lamination': return '💿';
      case 'Scanning': return '🔍';
      case 'Paper': return '📰';
      default: return '📦';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onAdd(p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceVariant : AppColors.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? _catColor.withValues(alpha: 0.5) : AppColors.borderColor,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: _catColor.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))]
                : [],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _catColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_catEmoji, style: const TextStyle(fontSize: 16)),
                  ),
                  const Spacer(),
                  if (p.isLowStock)
                    const Text('⚠️', style: TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              Text(p.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Text('PKR ${p.sellingPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: _catColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    )),
                  const Spacer(),
                  Text('/${p.unit}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: p.stockQuantity / (p.lowStockThreshold * 5).clamp(1, double.infinity),
                backgroundColor: AppColors.borderColor,
                valueColor: AlwaysStoppedAnimation(
                  p.isLowStock ? AppColors.accentOrange : AppColors.accentGreen,
                ),
                minHeight: 3,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends ConsumerStatefulWidget {
  final CartState cart;
  final String soldBy;
  final ValueChanged<SaleModel> onCheckout;
  const _CartPanel({required this.cart, required this.soldBy, required this.onCheckout});

  @override
  ConsumerState<_CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<_CartPanel> {
  final _discountCtrl = TextEditingController(text: '0');
  final _paidCtrl = TextEditingController(text: '0');
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  DateTime? _estimatedDelivery;

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;
    final fmt = NumberFormat('#,##0.00');
    return Column(
      children: [
        // Cart header
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Text('🛒', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Text('Cart', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (cart.items.isNotEmpty)
                TextButton(
                  onPressed: () => ref.read(cartProvider.notifier).clear(),
                  style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🧹', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text('Clear'),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderColor),
        
        // Customer Details Form (Collapsible or small)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customerNameCtrl,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Customer Name',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _customerPhoneCtrl,
                      style: const TextStyle(fontSize: 12),
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Cell #',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) {
                    if (!context.mounted) return;
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null) {
                      setState(() {
                        _estimatedDelivery = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _estimatedDelivery == null 
                            ? 'Set Delivery Date/Time' 
                            : DateFormat('dd/MM/yy hh:mm a').format(_estimatedDelivery!),
                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1, color: AppColors.borderColor),
        // Items
        Expanded(
          child: cart.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🛒', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Cart is empty', style: TextStyle(color: AppColors.textMuted)),
                      SizedBox(height: 6),
                      Text('Click a product to add it',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: cart.items.length,
                  itemBuilder: (context, i) {
                    final item = cart.items[i];
                    return _CartItem(
                      item: item,
                      onRemove: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
                      onQtyChange: (q) => ref.read(cartProvider.notifier).updateQuantity(item.product.id, q),
                    );
                  },
                ),
        ),
        // Totals & payment
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            border: Border(top: BorderSide(color: AppColors.borderColor)),
          ),
          child: Column(
            children: [
              _TotalRow(label: 'Subtotal', value: 'PKR ${fmt.format(cart.subtotal)}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Discount:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _discountCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          prefixText: 'PKR ',
                        ),
                        onChanged: (v) => ref.read(cartProvider.notifier).setDiscount(double.tryParse(v) ?? 0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _TotalRow(
                label: 'Total',
                value: 'PKR ${fmt.format(cart.netTotal)}',
                isTotal: true,
              ),
              const SizedBox(height: 12),
              // Payment method
              Row(
                children: ['Cash', 'Card', 'UPI'].map((m) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _PayMethod(
                      label: m,
                      selected: cart.paymentMethod == m,
                      onTap: () => ref.read(cartProvider.notifier).setPaymentMethod(m),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Advance/Paid:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _paidCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          prefixText: 'PKR ',
                        ),
                        onChanged: (v) => ref.read(cartProvider.notifier).setAmountPaid(double.tryParse(v) ?? 0),
                      ),
                    ),
                  ),
                ],
              ),
              if (cart.amountPaid > 0) ...[
                const SizedBox(height: 8),
                _TotalRow(
                  label: cart.change >= 0 ? 'Change' : 'Balance Remaining',
                  value: 'PKR ${fmt.format(cart.change >= 0 ? cart.change : cart.change.abs())}',
                  color: cart.change >= 0 ? AppColors.accentGreen : AppColors.accentRed,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: cart.items.isEmpty ? null : () => _completeSale(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.borderColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('✅', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text('Complete Sale', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Future<void> _completeSale(BuildContext context) async {
    final sale = await ref.read(cartProvider.notifier).checkout(
      soldBy: widget.soldBy,
      customerName: _customerNameCtrl.text,
      customerPhone: _customerPhoneCtrl.text,
      estimatedDelivery: _estimatedDelivery,
    );
    if (sale != null) {
      ref.read(inventoryProvider.notifier).reload();
      _discountCtrl.text = '0';
      _paidCtrl.text = '0';
      _customerNameCtrl.text = '';
      _customerPhoneCtrl.text = '';
      setState(() => _estimatedDelivery = null);
      widget.onCheckout(sale);
      if (context.mounted) {
        _showReceiptDialog(context, sale);
      }
    }
  }

  void _showReceiptDialog(BuildContext context, SaleModel sale) {
    showDialog(
      context: context,
      builder: (_) => _ReceiptDialog(sale: sale),
    );
  }
}

class _CartItem extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<double> onQtyChange;
  const _CartItem({required this.item, required this.onRemove, required this.onQtyChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.product.name,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                icon: const Text('❌', style: TextStyle(fontSize: 12)),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
              ),
            ],
          ),
          if (item.customDetails.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...item.customDetails.entries.map((e) => Text(
              '\u2022 ${e.key}: ${e.value}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
            )),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _QtyBtn(label: '－', onTap: () => onQtyChange(item.quantity - 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(item.quantity.toStringAsFixed(0),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              _QtyBtn(label: '＋', onTap: () => onQtyChange(item.quantity + 1)),
              const Spacer(),
              Text('PKR ${item.total.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QtyBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final bool isTotal;
  final Color? color;
  const _TotalRow({required this.label, required this.value, this.isTotal = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
          fontSize: isTotal ? 15 : 13,
        )),
        Text(value, style: TextStyle(
          color: color ?? (isTotal ? AppColors.primaryLight : AppColors.textPrimary),
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          fontSize: isTotal ? 16 : 13,
        )),
      ],
    );
  }
}

class _PayMethod extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PayMethod({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primary : AppColors.borderColor),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppColors.textSecondary,
          fontSize: 12, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }
}

class _ReceiptDialog extends StatelessWidget {
  final SaleModel sale;
  const _ReceiptDialog({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Text('🎉', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            Text('Sale Completed!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.accentGreen)),
            const SizedBox(height: 8),
            Text(DateFormat('dd/MM/yyyy HH:mm').format(sale.saleDate),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            ...sale.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Text('${item.quantity.toStringAsFixed(0)} × ${item.productName}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const Spacer(),
                Text('PKR ${item.total.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            )),
            const Divider(color: AppColors.borderColor, height: 24),
            Row(children: [
              const Text('TOTAL', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              Text('PKR ${sale.netAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w800, fontSize: 18)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text('Change:', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const Spacer(),
              Text('PKR ${sale.change.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => PdfService.printReceipt(sale),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryLight,
                      side: const BorderSide(color: AppColors.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🖨️', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Text('Print Receipt'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
