import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../providers/inventory_provider.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _search = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(inventoryProvider);
    final categories = ['All', ...ref.watch(categoriesProvider)];
    final filtered = products.where((p) {
      final matchSearch = p.name.toLowerCase().contains(_search.toLowerCase());
      final matchCat =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Text(
                      'Manage stock, prices, and units',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showProductDialog(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Add Product',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn().slideY(begin: -0.1),
            const SizedBox(height: 24),
            // Filters
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        dropdownColor: AppColors.cardColor,
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v!),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),
            // Stats bar
            Row(
              children: [
                _StockStat(
                  label: 'Total',
                  value: products.length.toString(),
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 16),
                _StockStat(
                  label: 'Low Stock',
                  value: products.where((p) => p.isLowStock).length.toString(),
                  color: AppColors.accentOrange,
                ),
                const SizedBox(width: 16),
                _StockStat(
                  label: 'Filtered',
                  value: filtered.length.toString(),
                  color: AppColors.accent,
                ),
              ],
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 20),
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Product Name',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Category',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Stock',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Cost Price',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Sell Price',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Status',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Actions',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            // Product list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        return _ProductRow(
                          product: p,
                          onEdit: () =>
                              _showProductDialog(context, ref, product: p),
                          onDelete: () => _confirmDelete(context, ref, p),
                          onStockUpdate: () =>
                              _showStockUpdateDialog(context, ref, p),
                          onViewDetails: () =>
                              _showProductDetailsDialog(context, ref, p),
                        ).animate().fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDialog(
    BuildContext context,
    WidgetRef ref, {
    ProductModel? product,
  }) {
    showDialog(
      context: context,
      builder: (_) => _ProductDialog(product: product, ref: ref),
    );
  }

  void _showProductDetailsDialog(
    BuildContext context,
    WidgetRef ref,
    ProductModel p,
  ) {
    showDialog(
      context: context,
      builder: (_) => _ProductDetailsDialog(product: p),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ProductModel p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(inventoryProvider.notifier).deleteProduct(p.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showStockUpdateDialog(
    BuildContext context,
    WidgetRef ref,
    ProductModel p,
  ) {
    final ctrl = TextEditingController(
      text: p.stockQuantity.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Update Stock: ${p.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Quantity (${p.unit})',
            prefixIcon: const Icon(Icons.inventory),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(ctrl.text) ?? p.stockQuantity;
              ref.read(inventoryProvider.notifier).updateStock(p.id, qty);
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _StockStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StockStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onEdit, onDelete, onStockUpdate, onViewDetails;
  const _ProductRow({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onStockUpdate,
    required this.onViewDetails,
  });

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onViewDetails,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceVariant : AppColors.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.borderColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    if (p.sampleImages.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.photo_library,
                          size: 14,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.category,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${p.stockQuantity.toStringAsFixed(0)} ${p.unit}',
                  style: TextStyle(
                    color: p.isLowStock
                        ? AppColors.accentOrange
                        : AppColors.textPrimary,
                    fontWeight: p.isLowStock
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'PKR ${p.costPrice.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'PKR ${p.sellingPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: p.isLowStock
                        ? AppColors.accentOrange.withValues(alpha: 0.1)
                        : AppColors.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.isLowStock ? '⚠ Low Stock' : '✓ In Stock',
                    style: TextStyle(
                      color: p.isLowStock
                          ? AppColors.accentOrange
                          : AppColors.accentGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                child: Row(
                  children: [
                    _ActionBtn(
                      icon: Icons.remove_red_eye_outlined,
                      color: AppColors.primaryLight,
                      tooltip: 'View Details',
                      onTap: widget.onViewDetails,
                    ),
                    const SizedBox(width: 4),
                    _ActionBtn(
                      icon: Icons.add_circle_outline,
                      color: AppColors.accentGreen,
                      tooltip: 'Add Stock',
                      onTap: widget.onStockUpdate,
                    ),
                    const SizedBox(width: 4),
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      color: AppColors.accent,
                      tooltip: 'Edit',
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(width: 4),
                    _ActionBtn(
                      icon: Icons.delete_outline,
                      color: AppColors.accentRed,
                      tooltip: 'Delete',
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final ProductModel? product;
  final WidgetRef ref;
  const _ProductDialog({this.product, required this.ref});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.product?.name ?? '',
  );
  late final TextEditingController _costPrice = TextEditingController(
    text: widget.product?.costPrice.toString() ?? '',
  );
  late final TextEditingController _sellPrice = TextEditingController(
    text: widget.product?.sellingPrice.toString() ?? '',
  );
  late final TextEditingController _stock = TextEditingController(
    text: widget.product?.stockQuantity.toString() ?? '',
  );
  late final TextEditingController _lowStock = TextEditingController(
    text: widget.product?.lowStockThreshold.toString() ?? '10',
  );
  late final TextEditingController _desc = TextEditingController(
    text: widget.product?.description ?? '',
  );
  late String _category = widget.product?.category ?? 'Copying';
  late String _unit = widget.product?.unit ?? 'pages';
  late List<String> _sampleImages = widget.product?.sampleImages.toList() ?? [];
  late List<String> _customFields = widget.product?.customFields.toList() ?? [];
  final TextEditingController _newFieldCtrl = TextEditingController();

  final _categories = [
    'Copying',
    'Printing',
    'Scanning',
    'Binding',
    'Lamination',
    'Paper',
    'Merch',
    'Gifts',
    'Cards',
    'Services',
    'Other',
  ];
  final _units = [
    'pages',
    'reams',
    'items',
    'sheets',
    'sets',
    'rolls',
    'sq-ft',
    'jobs',
  ];

  @override
  void dispose() {
    _newFieldCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _sampleImages.addAll(result.paths.whereType<String>());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 750,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.product == null
                          ? Icons.add_business_rounded
                          : Icons.edit_document,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.product == null ? 'Add New Product' : 'Edit Product',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Close',
                      splashRadius: 24,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info Section
                      const _SectionTitle(
                        title: 'Basic Information',
                        icon: Icons.info_outline,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _name,
                              decoration: const InputDecoration(
                                labelText: 'Product Name *',
                                prefixIcon: Icon(Icons.shopping_bag_outlined),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _DropdownField(
                              label: 'Category',
                              value: _category,
                              items: _categories,
                              onChanged: (v) => setState(() => _category = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Pricing Section
                      const _SectionTitle(
                        title: 'Pricing & Stock',
                        icon: Icons.monetization_on_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _costPrice,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cost Price *',
                                prefixText: 'PKR ',
                                prefixIcon: Icon(
                                  Icons.account_balance_wallet_outlined,
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _sellPrice,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Selling Price *',
                                prefixText: 'PKR ',
                                prefixIcon: Icon(Icons.sell_outlined),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stock,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stock Quantity *',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DropdownField(
                              label: 'Unit',
                              value: _unit,
                              items: _units,
                              onChanged: (v) => setState(() => _unit = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lowStock,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Low Stock Alert',
                                prefixIcon: Icon(Icons.warning_amber_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Additional Info Section
                      const _SectionTitle(
                        title: 'Additional Details',
                        icon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _desc,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Custom Fields
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.label_outline,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Custom Attributes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add variants like Size, Color, or Material',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ..._customFields.map(
                                  (f) => Chip(
                                    label: Text(
                                      f,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: AppColors.borderColor,
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.cancel,
                                      size: 18,
                                    ),
                                    onDeleted: () =>
                                        setState(() => _customFields.remove(f)),
                                  ),
                                ),
                                SizedBox(
                                  width: 200,
                                  height: 40,
                                  child: TextField(
                                    controller: _newFieldCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. A4 Size...',
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: AppColors.borderColor,
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: AppColors.primary,
                                        ),
                                        onPressed: () {
                                          if (_newFieldCtrl.text.isNotEmpty) {
                                            setState(() {
                                              _customFields.add(
                                                _newFieldCtrl.text.trim(),
                                              );
                                              _newFieldCtrl.clear();
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    onSubmitted: (v) {
                                      if (v.isNotEmpty) {
                                        setState(
                                          () => _customFields.add(v.trim()),
                                        );
                                        _newFieldCtrl.clear();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Images
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Product Images',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Upload'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _pickImages,
                                ),
                              ],
                            ),
                            if (_sampleImages.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _sampleImages
                                    .map((path) => _buildImageChip(path))
                                    .toList(),
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              const Center(
                                child: Text(
                                  'No images selected',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: Icon(
                      widget.product == null
                          ? Icons.check_circle_outline
                          : Icons.save_outlined,
                    ),
                    label: Text(
                      widget.product == null
                          ? 'Create Product'
                          : 'Save Changes',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageChip(String path) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              path.split(r'\').last.split('/').last,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() => _sampleImages.remove(path)),
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.accentRed,
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final notifier = widget.ref.read(inventoryProvider.notifier);
    if (widget.product == null) {
      notifier.addProduct(
        name: _name.text.trim(),
        category: _category,
        costPrice: double.parse(_costPrice.text),
        sellingPrice: double.parse(_sellPrice.text),
        stockQuantity: double.parse(_stock.text),
        unit: _unit,
        lowStockThreshold: double.tryParse(_lowStock.text) ?? 10,
        description: _desc.text,
        sampleImages: _sampleImages,
        customFields: _customFields,
      );
    } else {
      final p = widget.product!;
      p.name = _name.text.trim();
      p.category = _category;
      p.costPrice = double.parse(_costPrice.text);
      p.sellingPrice = double.parse(_sellPrice.text);
      p.stockQuantity = double.parse(_stock.text);
      p.unit = _unit;
      p.lowStockThreshold = double.tryParse(_lowStock.text) ?? 10;
      p.description = _desc.text;
      p.sampleImages = _sampleImages;
      p.customFields = _customFields;
      notifier.updateProduct(p);
    }
    Navigator.pop(context);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          dropdownColor: AppColors.cardColor,
          items: items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(
                    i,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ProductDetailsDialog extends StatefulWidget {
  final ProductModel product;
  const _ProductDetailsDialog({required this.product});

  @override
  State<_ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<_ProductDetailsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final fmt = NumberFormat('#,##0.00');
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 680,
        height: 580,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: const Border(
                  bottom: BorderSide(color: AppColors.borderColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: Theme.of(context).textTheme.headlineMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              p.category,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: const Text('PDF'),
                            onPressed:
                                p.sampleImages.isNotEmpty ||
                                    p.description.isNotEmpty
                                ? () => PdfService.generateProductSamplePdf(p)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryLight,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.primaryLight,
                    tabs: const [
                      Tab(text: 'Product Info'),
                      Tab(text: 'Samples & Gallery'),
                    ],
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ---- Info Tab ----
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price / Stock row
                        Row(
                          children: [
                            _InfoCard(
                              label: 'Selling Price',
                              value: 'PKR ${fmt.format(p.sellingPrice)}',
                              icon: Icons.sell,
                              color: AppColors.accentGreen,
                            ),
                            const SizedBox(width: 16),
                            _InfoCard(
                              label: 'Cost Price',
                              value: 'PKR ${fmt.format(p.costPrice)}',
                              icon: Icons.price_change,
                              color: AppColors.primaryLight,
                            ),
                            const SizedBox(width: 16),
                            _InfoCard(
                              label: 'Stock',
                              value:
                                  '${p.stockQuantity.toStringAsFixed(0)} ${p.unit}',
                              icon: Icons.inventory,
                              color: p.isLowStock
                                  ? AppColors.accentOrange
                                  : AppColors.accentGreen,
                            ),
                          ],
                        ),
                        if (p.description.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              p.description,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                        if (p.customFields.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Custom Fields Required',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: p.customFields
                                .map(
                                  (f) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.edit_note,
                                          size: 14,
                                          color: AppColors.primaryLight,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          f,
                                          style: const TextStyle(
                                            color: AppColors.primaryLight,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ---- Samples Tab ----
                  p.sampleImages.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 60,
                                color: AppColors.textMuted,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No sample images yet.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Edit this product to add samples.',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                          itemCount: p.sampleImages.length,
                          itemBuilder: (ctx, i) {
                            final path = p.sampleImages[i];
                            return GestureDetector(
                              onTap: () => _openImageViewer(ctx, path),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.borderColor,
                                  ),
                                  image: DecorationImage(
                                    image: FileImage(File(path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    margin: const EdgeInsets.all(6),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black38,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(child: Image.file(File(path), fit: BoxFit.contain)),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
