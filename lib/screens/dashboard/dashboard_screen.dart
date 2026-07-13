import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/sale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    final auth = ref.watch(authProvider);
    final lowStock = inventory.where((p) => p.isLowStock).toList();
    final today = DateTime.now();
    final monthRevenue = SaleService.getMonthRevenue(today.year, today.month);
    final monthInvestment = SaleService.getMonthInvestment(today.year, today.month, inventory);
    final monthProfit = SaleService.getMonthProfit(today.year, today.month, inventory);
    final totalProducts = inventory.length;
    final fmt = NumberFormat('#,##0');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────
                  _Header(
                    today: today,
                    username: auth.currentUser?.username ?? '',
                  ).animate().fadeIn().slideY(begin: -0.1),

                  const SizedBox(height: 16),

                  // ── Stats Row ──────────────────────────────────────
                  // Use IntrinsicHeight so cards match each other's height
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Revenue',
                            value: 'PKR ${fmt.format(monthRevenue)}',
                            emoji: '📈',
                            gradient: AppColors.primaryGradient,
                            delta: DateFormat('MMM yyyy').format(today),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Investment',
                            value: 'PKR ${fmt.format(monthInvestment)}',
                            emoji: '💼',
                            gradient: AppColors.orangeGradient,
                            delta: DateFormat('MMM yyyy').format(today),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Profit',
                            value: 'PKR ${fmt.format(monthProfit)}',
                            emoji: '💰',
                            gradient: AppColors.greenGradient,
                            delta: DateFormat('MMM yyyy').format(today),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Products',
                            value: totalProducts.toString(),
                            emoji: '📦',
                            gradient: AppColors.primaryGradient,
                            delta: '${lowStock.length} low',
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 16),

                  // ── Bottom panels ──────────────────────────────────
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _LowStockPanel(lowStock: lowStock),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: _QuickActionsPanel(),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final DateTime today;
  final String username;
  const _Header({required this.today, required this.username});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand logo — fixed, doesn't grow
        const BrandLogo(fontSize: 22),
        const SizedBox(width: 16),
        // Thin divider
        Container(width: 1, height: 40, color: AppColors.borderColor),
        const SizedBox(width: 16),
        // Date — can shrink if needed
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(today),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                DateFormat('yyyy').format(today),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Welcome badge — can shrink
        _WelcomeBadge(username: username),
      ],
    );
  }
}

// ── Welcome Badge ────────────────────────────────────────────────────────────
class _WelcomeBadge extends StatelessWidget {
  final String username;
  const _WelcomeBadge({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              'Hi, $username',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────
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
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.borderColor,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ← key fix: don't try to fill height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.delta,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Low Stock Panel ──────────────────────────────────────────────────────────
class _LowStockPanel extends StatelessWidget {
  final List lowStock;
  const _LowStockPanel({required this.lowStock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Low Stock Alerts',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: lowStock.isEmpty
                      ? AppColors.accentGreen.withValues(alpha: 0.15)
                      : AppColors.accentOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${lowStock.length} items',
                  style: TextStyle(
                    color: lowStock.isEmpty
                        ? AppColors.accentGreen
                        : AppColors.accentOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: lowStock.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('✅', style: TextStyle(fontSize: 36)),
                        SizedBox(height: 6),
                        Text(
                          'All stocks sufficient!',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: lowStock.length,
                    itemBuilder: (context, i) {
                      final p = lowStock[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.accentOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${p.stockQuantity.toStringAsFixed(0)} ${p.unit}',
                              style: const TextStyle(
                                color: AppColors.accentOrange,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions Panel ──────────────────────────────────────────────────────
class _QuickActionsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      ('💻', 'New Sale', AppColors.primaryGradient, '/pos'),
      ('➕', 'Add Stock', AppColors.greenGradient, '/inventory/add'),
      ('📊', 'Monthly Report', AppColors.orangeGradient, '/history'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _QuickActionBtn(
                emoji: a.$1,
                label: a.$2,
                gradient: a.$3,
                path: a.$4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Button ──────────────────────────────────────────────────────
class _QuickActionBtn extends StatefulWidget {
  final String emoji;
  final String label;
  final LinearGradient gradient;
  final String path;
  const _QuickActionBtn({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.path,
  });

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceVariant : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Text(
                '▶',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
