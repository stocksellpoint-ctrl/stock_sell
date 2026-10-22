import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:stock_sell/core/constants/app_size.dart';
import 'package:stock_sell/core/widgets/app_drawer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../data/models/inventory_report_model.dart';
import '../../data/models/profit_report_model.dart';
import '../providers/report_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReportProvider>();
      if (provider.inventoryReport == null && !provider.isLoading) {
        provider.loadInventory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              if (provider.tab == ReportTab.inventory) {
                provider.loadInventory();
              } else {
                provider.loadProfit();
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _segmentedControl(provider),
          Expanded(
            child: provider.tab == ReportTab.inventory
                ? const _InventoryReportView()
                : const _ProfitReportView(),
          ),
        ],
      ),
    );
  }

  Widget _segmentedControl(ReportProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _segmentTab(
                label: 'Inventory',
                icon: Icons.inventory_2_outlined,
                selected: provider.tab == ReportTab.inventory,
                onTap: () => provider.setTab(ReportTab.inventory),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _segmentTab(
                label: 'Profit',
                icon: Icons.trending_up,
                selected: provider.tab == ReportTab.profit,
                onTap: () => provider.setTab(ReportTab.profit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentTab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm - 2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Inventory Report View
// ═══════════════════════════════════════════════════════════════

class _InventoryReportView extends StatelessWidget {
  const _InventoryReportView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final report = provider.inventoryReport;

    if (provider.isLoading && report == null) {
      return const LoadingIndicator(message: 'Loading inventory report...');
    }

    if (provider.error != null && report == null) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.loadInventory(),
      );
    }

    if (report == null || report.totals.products == 0) {
      return const EmptyView(
        icon: Icons.inventory_2_outlined,
        title: 'No products',
        subtitle: 'Add products to see inventory value.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadInventory(),
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          // ★ UPDATED: Only Cost Value
          Row(
            children: [
              Expanded(
                child: _bigStatCard(
                  label: 'Stock Cost Value',
                  value: Formatters.currency(report.totals.costValue),
                  icon: Icons.shopping_cart_outlined,
                  color: AppColors.primary,
                  highlight: true,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  children: [
                    _miniStatCard(
                      label: 'Products',
                      value: '${report.totals.products}',
                      icon: Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    _miniStatCard(
                      label: 'Items',
                      value: '${report.totals.items}',
                      icon: Icons.numbers,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (report.lowStock.isNotEmpty) ...[
            const SizedBox(height: AppSizes.lg),
            _section(
              title: 'Low Stock Alert',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${report.lowStock.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              child: Column(
                children: report.lowStock.take(5).map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.sku,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.quantity} / ${item.lowStockThreshold}',
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          if (report.categories.isNotEmpty) ...[
            const SizedBox(height: AppSizes.lg),
            _section(
              title: 'Value by Category',
              child: Column(
                children: report.categories.map((c) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.categoryName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              // ★ UPDATED: Changed to costValue
                              Formatters.currency(c.costValue),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          // ★ UPDATED: Removed Profit calculation
                          '${c.products} products • ${c.quantity} items',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Profit Report View
// ═══════════════════════════════════════════════════════════════

class _ProfitReportView extends StatelessWidget {
  const _ProfitReportView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final report = provider.profitReport;

    return Column(
      children: [
        _periodSelector(context, provider),
        Expanded(
          child: provider.isLoading && report == null
              ? const LoadingIndicator(message: 'Loading profit report...')
              : provider.error != null && report == null
              ? ErrorView(
                  message: provider.error!,
                  onRetry: () => provider.loadProfit(),
                )
              : report == null || report.totals.orders == 0
              ? EmptyView(
                  icon: Icons.trending_up,
                  title: 'No sales in this period',
                  subtitle:
                      'Try a different period. (${provider.profitPeriodLabel})',
                )
              : _profitBody(provider, report),
        ),
      ],
    );
  }

  Widget _periodSelector(BuildContext context, ReportProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _periodChip(
                  label: 'Daily',
                  value: ProfitPeriod.daily,
                  current: provider.profitPeriod,
                  onTap: provider.setProfitPeriod,
                ),
                const SizedBox(width: 8),
                _periodChip(
                  label: 'Weekly',
                  value: ProfitPeriod.weekly,
                  current: provider.profitPeriod,
                  onTap: provider.setProfitPeriod,
                ),
                const SizedBox(width: 8),
                _periodChip(
                  label: 'Fortnightly',
                  value: ProfitPeriod.fortnightly,
                  current: provider.profitPeriod,
                  onTap: provider.setProfitPeriod,
                ),
                const SizedBox(width: 8),
                _periodChip(
                  label: 'Monthly',
                  value: ProfitPeriod.monthly,
                  current: provider.profitPeriod,
                  onTap: provider.setProfitPeriod,
                ),
                const SizedBox(width: 8),
                _periodChip(
                  label: 'Custom',
                  value: ProfitPeriod.custom,
                  current: provider.profitPeriod,
                  onTap: (p) async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: now,
                      initialDateRange:
                          provider.customRange ??
                          DateTimeRange(
                            start: now.subtract(const Duration(days: 7)),
                            end: now,
                          ),
                    );
                    if (picked != null) {
                      provider.setCustomRange(picked);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.date_range_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                provider.profitPeriodLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodChip({
    required String label,
    required ProfitPeriod value,
    required ProfitPeriod current,
    required Future<void> Function(ProfitPeriod) onTap,
  }) {
    final selected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(value),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    );
  }

  Widget _profitBody(ReportProvider provider, ProfitReportModel report) {
    return RefreshIndicator(
      onRefresh: () => provider.loadProfit(),
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: _bigStatCard(
                  label: 'Revenue',
                  value: Formatters.currency(report.totals.revenue),
                  icon: Icons.trending_up,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: _bigStatCard(
                  label: 'Cost',
                  value: Formatters.currency(report.totals.cost),
                  icon: Icons.trending_down,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: report.totals.profit >= 0
                  ? AppColors.success
                  : AppColors.danger,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      report.totals.profit >= 0 ? 'NET PROFIT' : 'NET LOSS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${report.totals.margin.toStringAsFixed(1)}% margin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.currency(report.totals.profit),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: _miniStatCard(
                  label: 'Orders',
                  value: '${report.totals.orders}',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _miniStatCard(
                  label: 'Items Sold',
                  value: '${report.totals.itemsSold}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            ],
          ),

          // ★ UPDATED: Closing Inventory Block
          const SizedBox(height: AppSizes.lg),
          _section(
            title: 'Inventory Closing Balance (Cost)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'As of ${Formatters.date(report.to)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    Expanded(
                      child: _bigStatCard(
                        label: 'Closing Stock Cost',
                        value: Formatters.currency(
                          report.closingInventory.stockCostValue,
                        ),
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: _bigStatCard(
                        label: 'Closing Items',
                        value: '${report.closingInventory.totalItems}',
                        icon: Icons.numbers,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),
          _section(title: 'Daily Breakdown', child: _dailyList(report.daily)),

          if (report.topProducts.isNotEmpty) ...[
            const SizedBox(height: AppSizes.lg),
            _section(
              title: 'Top Products by Profit',
              child: Column(
                children: report.topProducts.asMap().entries.map((e) {
                  final index = e.key;
                  final p = e.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index < 3 ? AppColors.primary : AppColors.bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: index < 3
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${p.quantity} sold • '
                                'Rev: ${Formatters.currency(p.revenue)} • '
                                'Cost: ${Formatters.currency(p.cost)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.currency(p.profit),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: p.profit >= 0
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }

  Widget _dailyList(List<DailyProfitStat> daily) {
    if (daily.isEmpty) {
      return const Text(
        'No daily data',
        style: TextStyle(color: AppColors.textLight),
      );
    }

    final maxRevenue = daily
        .map((d) => d.revenue)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: daily.map((d) {
        final fraction = maxRevenue > 0 ? d.revenue / maxRevenue : 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '${d.date.day}/${d.date.month}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: fraction.clamp(0.05, 1.0).toDouble(),
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profit: ${Formatters.currency(d.profit)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              Formatters.currency(d.revenue),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shared widgets
// ═══════════════════════════════════════════════════════════════

Widget _bigStatCard({
  required String label,
  required String value,
  required IconData icon,
  required Color color,
  bool highlight = false,
}) {
  return Container(
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      color: highlight ? color : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: highlight ? null : Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: highlight ? Colors.white : color, size: 22),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: highlight ? Colors.white70 : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: highlight ? Colors.white : AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget _miniStatCard({
  required String label,
  required String value,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    ),
  );
}

Widget _section({
  required String title,
  required Widget child,
  Widget? trailing,
}) {
  return Container(
    padding: const EdgeInsets.all(AppSizes.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: AppSizes.md),
        child,
      ],
    ),
  );
}
