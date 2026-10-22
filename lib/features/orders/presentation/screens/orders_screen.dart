import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:stock_sell/core/constants/app_size.dart';
import 'package:stock_sell/core/widgets/app_drawer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';

enum OrderSortOption {
  newestFirst,
  oldestFirst,
  amountHighToLow,
  amountLowToHigh,
}

extension OrderSortOptionX on OrderSortOption {
  String get label {
    switch (this) {
      case OrderSortOption.newestFirst:
        return 'Newest First';
      case OrderSortOption.oldestFirst:
        return 'Oldest First';
      case OrderSortOption.amountHighToLow:
        return 'Amount: High → Low';
      case OrderSortOption.amountLowToHigh:
        return 'Amount: Low → High';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderSortOption.newestFirst:
        return Icons.arrow_downward;
      case OrderSortOption.oldestFirst:
        return Icons.arrow_upward;
      case OrderSortOption.amountHighToLow:
        return Icons.trending_down;
      case OrderSortOption.amountLowToHigh:
        return Icons.trending_up;
    }
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  OrderSortOption _sort = OrderSortOption.newestFirst;
  String? _categoryFilter;

  /// Tracks WHICH order is currently being deleted.
  /// Only that order's card shows the loading spinner.
  String? _deletingOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
      final catProvider = context.read<CategoryProvider>();
      if (catProvider.categories.isEmpty) {
        catProvider.loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<OrderModel> _applyFilters(List<OrderModel> orders) {
    var result = orders.toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((o) {
        final idMatch = o.id?.toLowerCase().contains(q) ?? false;
        final nameMatch = o.customerName.toLowerCase().contains(q);
        return idMatch || nameMatch;
      }).toList();
    }

    if (_categoryFilter != null) {
      result = result.where((o) {
        return o.items.any((i) => i.categoryId == _categoryFilter);
      }).toList();
    }

    switch (_sort) {
      case OrderSortOption.newestFirst:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case OrderSortOption.oldestFirst:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case OrderSortOption.amountHighToLow:
        result.sort((a, b) => b.total.compareTo(a.total));
        break;
      case OrderSortOption.amountLowToHigh:
        result.sort((a, b) => a.total.compareTo(b.total));
        break;
    }

    return result;
  }

  Future<void> _handleDelete(OrderModel order) async {
    // Only one delete at a time
    if (_deletingOrderId != null) return;

    final provider = context.read<OrderProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Order?'),
        content: Text(
          'Order #${order.id?.substring(0, 8) ?? ''} for ${order.customerName}. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mark ONLY this order as deleting → only its card shows loading
    setState(() => _deletingOrderId = order.id);

    final ok = await provider.deleteOrder(order.id!);

    if (!mounted) return;

    setState(() => _deletingOrderId = null);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to delete'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showSortPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: 8,
                ),
                child: Text(
                  'Sort by',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ...OrderSortOption.values.map(
                (opt) => ListTile(
                  leading: Icon(
                    opt.icon,
                    color: _sort == opt
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    opt.label,
                    style: TextStyle(
                      fontWeight: _sort == opt
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _sort == opt ? AppColors.primary : null,
                    ),
                  ),
                  trailing: _sort == opt
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _sort = opt);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final categories = context.watch<CategoryProvider>().categories;
    final filtered = _applyFilters(provider.orders);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            tooltip: 'New Sale',
            onPressed: () => context.push('/orders/new'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadOrders(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(categories),
          _buildResultCount(provider.orders.length, filtered.length),
          Expanded(child: _buildList(provider, filtered)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.md,
        AppSizes.lg,
        AppSizes.sm,
      ),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by customer or order #',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Badge(
              isLabelVisible: _sort != OrderSortOption.newestFirst,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.sort),
            ),
            onPressed: _showSortPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List categories) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _categoryFilter == null,
              onSelected: (_) => setState(() => _categoryFilter = null),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: _categoryFilter == null
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: _categoryFilter == null
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: _categoryFilter == null
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
            const SizedBox(width: 8),
            ...categories.map((c) {
              final selected = _categoryFilter == c.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c.name),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _categoryFilter = selected ? null : c.id),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCount(int total, int filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: 6),
      color: AppColors.bg,
      child: Text(
        filtered == total
            ? '$total order${total == 1 ? '' : 's'}'
            : 'Showing $filtered of $total orders',
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildList(OrderProvider provider, List<OrderModel> orders) {
    if (provider.isLoading && provider.orders.isEmpty)
      return const LoadingIndicator(message: 'Loading orders...');
    if (provider.error != null && provider.orders.isEmpty) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.loadOrders(),
      );
    }
    if (orders.isEmpty) {
      if (provider.orders.isEmpty)
        return const EmptyView(
          icon: Icons.receipt_long_outlined,
          title: 'No sales yet',
          subtitle: 'Orders you create will appear here.',
        );
      return EmptyView(
        icon: Icons.search_off,
        title: 'No matches',
        subtitle: 'Try a different search or filter.',
        action: TextButton.icon(
          onPressed: () {
            _searchCtrl.clear();
            setState(() {
              _searchQuery = '';
              _categoryFilter = null;
            });
          },
          icon: const Icon(Icons.clear),
          label: const Text('Clear filters'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadOrders(),
      child: ListView.separated(
        // Add bottom padding so the last item is not hidden behind the FAB
        padding: const EdgeInsets.fromLTRB(
          AppSizes.lg,
          AppSizes.lg,
          AppSizes.lg,
          80,
        ),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
        itemBuilder: (_, i) {
          final order = orders[i];
          return _OrderCard(
            order: order,
            // Only the order being deleted shows the loading state
            isDeleting: _deletingOrderId == order.id,
            onTap: () => context.push('/orders/${order.id}'),
            onDelete: () => _handleDelete(order),
          );
        },
      ),
    );
  }
}

// class _OrderCard extends StatelessWidget {
//   final OrderModel order;
//   final VoidCallback onTap;
//   final VoidCallback onDelete;
//   final bool isDeleting;

//   const _OrderCard({
//     required this.order,
//     required this.onTap,
//     required this.onDelete,
//     this.isDeleting = false,
//   });

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'pending': return AppColors.warning;
//       case 'processing': return AppColors.info;
//       case 'completed': return AppColors.success;
//       case 'cancelled': return AppColors.danger;
//       default: return AppColors.textSecondary;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(AppSizes.radiusMd),
//       child: Container(
//         padding: const EdgeInsets.all(AppSizes.lg),
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.circular(AppSizes.radiusMd),
//           border: Border.all(color: AppColors.border),
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Text('Order #${(order.id ?? '').substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
//                       const SizedBox(width: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                         decoration: BoxDecoration(color: _statusColor(order.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
//                         child: Text(order.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _statusColor(order.status))),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Text(order.customerName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
//                   const SizedBox(height: 4),
//                   Text('${order.items.length} item(s) • ${Formatters.dateTime(order.createdAt)}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
//                 ],
//               ),
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(Formatters.currency(order.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                 if (order.hasDiscount) ...[
//                   const SizedBox(height: 2),
//                   Text('-${Formatters.currency(order.discountAmount)}', style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600)),
//                 ],
//                 const SizedBox(height: 8),
//                 InkWell(
//                   onTap: isDeleting ? null : onDelete,
//                   borderRadius: BorderRadius.circular(6),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(6)),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         isDeleting
//                             ? const SizedBox(
//                                 width: 14,
//                                 height: 14,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: AppColors.danger,
//                                 ),
//                               )
//                             : const Icon(Icons.delete_outline, size: 14, color: AppColors.danger),
//                         const SizedBox(width: 4),
//                         Text(
//                           isDeleting ? 'Deleting...' : 'Delete',
//                           style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isDeleting;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onDelete,
    this.isDeleting = false,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left column: order info ─────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${(order.id ?? '').substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.customerName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.items.length} item(s) • ${Formatters.dateTime(order.createdAt)}',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // ── Right column: price, status, delete ─────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(order.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (order.hasDiscount) ...[
                  const SizedBox(height: 2),
                  Text(
                    '-${Formatters.currency(order.discountAmount)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),

                // ★ Status badge now lives here
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                InkWell(
                  onTap: isDeleting ? null : onDelete,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        isDeleting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.danger,
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline,
                                size: 14,
                                color: AppColors.danger,
                              ),
                        const SizedBox(width: 4),
                        Text(
                          isDeleting ? 'Deleting...' : 'Delete',
                          style: const TextStyle(
                            color: AppColors.danger,
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
          ],
        ),
      ),
    );
  }
}
