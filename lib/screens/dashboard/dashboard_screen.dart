import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/sale_service.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    final auth = ref.watch(authProvider);
    final lowStock = inventory.where((p) => p.isLowStock).toList();
    final today = DateTime.now();
    final todayRevenue = SaleService.getTodayRevenue();
    final todayCount = SaleService.getTodayTransactionCount();
    final monthRevenue = SaleService.getMonthRevenue(today.year, today.month);
    final totalProducts = inventory.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
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
                    Text('Dashboard', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(today),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const Spacer(),
                _WelcomeBadge(username: auth.currentUser?.username ?? ''),
              ],
            ).animate().fadeIn().slideY(begin: -0.1),
            const SizedBox(height: 32),
            // Stats row
            Row(
              children: [
                Expanded(child: _StatCard(
                  label: "Today's Revenue",
                  value: 'PKR ${NumberFormat('#,##0.00').format(todayRevenue)}',
                  emoji: '💵',
                  gradient: AppColors.primaryGradient,
                  delta: '+Today',
                )),
                const SizedBox(width: 20),
                Expanded(child: _StatCard(
                  label: "Today's Sales",
                  value: todayCount.toString(),
                  emoji: '📝',
                  gradient: AppColors.greenGradient,
                  delta: 'Transactions',
                )),
                const SizedBox(width: 20),
                Expanded(child: _StatCard(
                  label: 'Month Revenue',
                  value: 'PKR ${NumberFormat('#,##0.00').format(monthRevenue)}',
                  emoji: '📈',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  delta: DateFormat('MMMM').format(today),
                )),
                const SizedBox(width: 20),
                Expanded(child: _StatCard(
                  label: 'Total Products',
                  value: totalProducts.toString(),
                  emoji: '📦',
                  gradient: AppColors.orangeGradient,
                  delta: '${lowStock.length} low stock',
                )),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Low stock alerts
                Expanded(
                  flex: 5,
                  child: _LowStockPanel(lowStock: lowStock),
                ),
                const SizedBox(width: 20),
                // Quick actions
                Expanded(
                  flex: 4,
                  child: _QuickActionsPanel(),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBadge extends StatelessWidget {
  final String username;
  const _WelcomeBadge({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'U',
              style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Text('Welcome, $username', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String label;
  final String value;
  final String emoji;
  final LinearGradient gradient;
  final String delta;

  const _StatCard({
    required this.label,
    required this.value,
    required this.emoji,
    required this.gradient,
    required this.delta,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovered ? AppColors.primary.withOpacity(0.4) : AppColors.borderColor),
          boxShadow: _hovered
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(widget.emoji, style: const TextStyle(fontSize: 18)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(widget.delta,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(widget.value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(widget.label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _LowStockPanel extends StatelessWidget {
  final List lowStock;
  const _LowStockPanel({required this.lowStock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Text('Low Stock Alerts', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: lowStock.isEmpty ? AppColors.accentGreen.withOpacity(0.15) : AppColors.accentOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${lowStock.length} items',
                  style: TextStyle(
                    color: lowStock.isEmpty ? AppColors.accentGreen : AppColors.accentOrange,
                    fontWeight: FontWeight.w600, fontSize: 12,
                  )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (lowStock.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text('All stocks are sufficient!',
                      style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            ...lowStock.take(8).map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accentOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(p.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                  Text('${p.stockQuantity.toStringAsFixed(0)} ${p.unit}',
                    style: const TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      ('💻', 'New Sale', AppColors.primaryGradient, '/pos'),
      ('➕', 'Add Stock', AppColors.greenGradient, '/inventory/add'),
      ('📊', 'Monthly Report', AppColors.orangeGradient, '/history'),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          ...actions.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _QuickActionBtn(emoji: a.$1, label: a.$2, gradient: a.$3, path: a.$4),
          )),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatefulWidget {
  final String emoji;
  final String label;
  final LinearGradient gradient;
  final String path;
  const _QuickActionBtn({required this.emoji, required this.label, required this.gradient, required this.path});

  @override
  State<_QuickActionBtn> createState() => _QuickActionBtnState();
}

class _QuickActionBtnState extends State<_QuickActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.path),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceVariant : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hovered ? AppColors.primary.withOpacity(0.4) : AppColors.borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(widget.emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 14),
              Text(widget.label,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const Spacer(),
              const Text('▶', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
