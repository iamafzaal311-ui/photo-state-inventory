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
  SaleModel? _lastSale;

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
      body: Row(
        children: [
          // Products panel (left)
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Point of Sale', style: Theme.of(context).textTheme.headlineLarge)
                      .animate().fadeIn().slideY(begin: -0.1),
                  const SizedBox(height: 20),
                  // Search & category filter
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: Center(widthFactor: 1, heightFactor: 1, child: Text('🔍', style: TextStyle(fontSize: 16))),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (v) => setState(() => _searchProduct = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories.take(8).map((c) => Padding(
                              padding: const EdgeInsets.only(left: 8),
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
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1,
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
          // Cart panel (right)
          Container(
            width: 340,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(left: BorderSide(color: AppColors.borderColor)),
            ),
            child: _CartPanel(
              cart: cart,
              soldBy: auth.currentUser?.username ?? 'Staff',
              onCheckout: (sale) => setState(() => _lastSale = sale),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddProduct(ProductModel p) async {
    if (p.customFields.isEmpty) {
      ref.read(cartProvider.notifier).addItem(p);
      return;
    }
    // Show custom fields dialog
    final details = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        final Map<String, TextEditingController> ctrls = {
          for (var f in p.customFields) f: TextEditingController()
        };
        return AlertDialog(
          title: Text('Custom Details: ${p.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: p.customFields.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: ctrls[f],
                  decoration: InputDecoration(labelText: f),
                ),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final result = <String, String>{};
                for (var f in p.customFields) {
                  result[f] = ctrls[f]!.text;
                }
                Navigator.pop(ctx, result);
              },
              child: const Text('Add to Cart'),
            ),
          ],
        );
      },
    );

    if (details != null) {
      ref.read(cartProvider.notifier).addItem(p, customDetails: details);
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
              color: _hovered ? _catColor.withOpacity(0.5) : AppColors.borderColor,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: _catColor.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6))]
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
                      color: _catColor.withOpacity(0.15),
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
                  const Text('Discount:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 8),
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
                  const Text('Amount Paid:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 8),
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
              if (cart.amountPaid > 0 && cart.change >= 0) ...[
                const SizedBox(height: 8),
                _TotalRow(label: 'Change', value: 'PKR ${fmt.format(cart.change)}', color: AppColors.accentGreen),
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
    final sale = await ref.read(cartProvider.notifier).checkout(soldBy: widget.soldBy);
    if (sale != null) {
      ref.read(inventoryProvider.notifier).reload();
      _discountCtrl.text = '0';
      _paidCtrl.text = '0';
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
                color: AppColors.accentGreen.withOpacity(0.15),
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
