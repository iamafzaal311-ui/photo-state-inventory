import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/sale_model.dart';
import '../../services/sale_service.dart';
import '../../services/pdf_service.dart';
import '../../services/report_service.dart';
import '../../theme/app_theme.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime _selectedMonth = DateTime.now();
  SaleModel? _expandedSale;

  MonthlyReportData get _reportData =>
      ReportService.generateMonthlyReportData(_selectedMonth.year, _selectedMonth.month);

  @override
  Widget build(BuildContext context) {
    final reportData = _reportData;
    final sales = reportData.sales;
    
    final dailyMap = SaleService.getDailySalesForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    final fmt = NumberFormat('#,##0.00');

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
                      'Sales History',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Text(
                      'Monthly analysis and reports',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const Spacer(),
                // Month picker
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Text('◀', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        onPressed: () => setState(
                          () => _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month - 1,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          DateFormat('MMMM yyyy').format(_selectedMonth),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Text('▶', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        onPressed:
                            _selectedMonth.month == DateTime.now().month &&
                                _selectedMonth.year == DateTime.now().year
                            ? null
                            : () => setState(
                                () => _selectedMonth = DateTime(
                                  _selectedMonth.year,
                                  _selectedMonth.month + 1,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _GradientButton(
                  emoji: '📄',
                  label: 'Export PDF',
                  gradient: AppColors.orangeGradient,
                  onTap: () => PdfService.generateMonthlyReport(reportData),
                ),
                const SizedBox(width: 12),
                _GradientButton(
                  emoji: '📂',
                  label: 'Open Reports',
                  gradient: AppColors.greenGradient,
                  onTap: () async {
                    final directory = await getApplicationDocumentsDirectory();
                    final reportsPath = '${directory.path}/InventoryManData/Reports';
                    final dir = Directory(reportsPath);
                    if (!await dir.exists()) {
                      await dir.create(recursive: true);
                    }
                    if (Platform.isWindows) {
                      await Process.run('explorer.exe', [reportsPath.replaceAll('/', '\\')]);
                    }
                  },
                ),
              ],
            ).animate().fadeIn().slideY(begin: -0.1),
            const SizedBox(height: 28),
            // Summary cards
            Row(
              children: [
                _SummaryCard(
                  label: 'Revenue',
                  value: 'PKR ${fmt.format(reportData.totalRevenue)}',
                  emoji: '💵',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 16),
                _SummaryCard(
                  label: 'Cost',
                  value: 'PKR ${fmt.format(reportData.totalCost)}',
                  emoji: '🛒',
                  color: AppColors.accentOrange,
                ),
                const SizedBox(width: 16),
                _SummaryCard(
                  label: 'Profit (Bachat)',
                  value: 'PKR ${fmt.format(reportData.totalProfit)}',
                  emoji: '📈',
                  color: AppColors.accentGreen,
                ),
                const SizedBox(width: 16),
                _SummaryCard(
                  label: 'Transactions',
                  value: '${reportData.totalTransactions}',
                  emoji: '📝',
                  color: AppColors.accent,
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
            // Sales list
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transactions list
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '📋',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Transactions',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            Text(
                              '${sales.length} records',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: sales.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '📭',
                                        style: TextStyle(fontSize: 48),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No sales this month',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: sales.length,
                                  itemBuilder: (ctx, i) {
                                    final s = sales[i];
                                    return _SaleRow(
                                      sale: s,
                                      isExpanded: _expandedSale?.id == s.id,
                                      onTap: () => setState(
                                        () => _expandedSale =
                                            _expandedSale?.id == s.id
                                            ? null
                                            : s,
                                      ),
                                      onPrint: () => PdfService.printReceipt(s),
                                    ).animate().fadeIn(
                                      delay: Duration(milliseconds: 40 * i),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Daily breakdown
                  Expanded(
                    flex: 3,
                    child: _DailyBreakdown(
                      dailyMap: dailyMap,
                      month: _selectedMonth,
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
}

class _GradientButton extends StatelessWidget {
  final String emoji;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _GradientButton({
    required this.emoji,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final String emoji;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
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

class _SaleRow extends StatelessWidget {
  final SaleModel sale;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onPrint;
  const _SaleRow({
    required this.sale,
    required this.isExpanded,
    required this.onTap,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.borderColor,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '📄',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(sale.saleDate),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          if (sale.orderNumber.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                sale.orderNumber,
                                style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${sale.items.length} items • ${sale.paymentMethod} • ${sale.soldBy}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Order status badge
                  if (sale.orderStatus.isNotEmpty &&
                      sale.orderStatus != 'Completed')
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          sale.orderStatus,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _statusColor(
                            sale.orderStatus,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        sale.orderStatus,
                        style: TextStyle(
                          color: _statusColor(sale.orderStatus),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    'PKR ${sale.netAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isExpanded ? '▲' : '▼',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.borderColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...sale.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              const Text(
                                '•',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${item.quantity.toStringAsFixed(0)} ${item.unit} × ${item.productName}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                'PKR ${item.total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (item.customDetails.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 24, top: 2),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: item.customDetails.entries
                                    .map(
                                      (e) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '• ${e.key}: ${e.value}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (sale.discount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        const Text(
                          'Discount:',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '- PKR ${sale.discount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.accentRed,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: onPrint,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          side: const BorderSide(color: AppColors.borderColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🖨️', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 6),
                            Text('Print Receipt'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.accentOrange;
      case 'In Progress':
        return AppColors.primaryLight;
      case 'Ready':
        return AppColors.accentGreen;
      case 'Delivered':
        return const Color(0xFF059669);
      case 'Cancelled':
        return AppColors.accentRed;
      default:
        return AppColors.textMuted;
    }
  }
}

class _DailyBreakdown extends StatelessWidget {
  final Map<String, double> dailyMap;
  final DateTime month;
  const _DailyBreakdown({required this.dailyMap, required this.month});

  @override
  Widget build(BuildContext context) {
    final sorted = dailyMap.entries.toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
    final maxVal = dailyMap.values.isEmpty
        ? 1.0
        : dailyMap.values.reduce((a, b) => a > b ? a : b);
    final fmt = NumberFormat('#,##0');

    return Container(
      padding: const EdgeInsets.all(20),
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
              const Text('📊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Daily Breakdown',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sorted.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No data',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (ctx, i) {
                  final entry = sorted[i];
                  final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.borderColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: ratio,
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 64,
                          child: Text(
                            fmt.format(entry.value),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
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
