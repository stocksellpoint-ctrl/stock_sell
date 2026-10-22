import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stock_sell/core/widgets/app_drawer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_size.dart';
import '../../../core/routes/route_names.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../customers/presentation/providers/customer_provider.dart';
import '../../inventory/presentation/providers/inventory_provider.dart';
import '../../orders/presentation/providers/order_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadProducts();
      context.read<CustomerProvider>().loadCustomers();
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final customers = context.watch<CustomerProvider>();
    final orders = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();

    // ★ Changed to use costPrice instead of price
    final totalStockValue = inventory.products.fold<double>(
      0,
      (sum, p) => sum + p.costPrice * p.quantity,
    );

    void switchTab(int index) {
      StatefulNavigationShell.of(context).goBranch(index);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${auth.user?.name ?? 'User'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            tooltip: 'New Sale',
            onPressed: () => context.push('/orders/new'),
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
            onPressed: () => context.push('/home/categories'),
          ),
          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   onPressed: () async {
          //     await auth.logout();
          //     if (context.mounted) context.go(RouteNames.login);
          //   },
          // ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            inventory.loadProducts(),
            customers.loadCustomers(),
            orders.loadOrders(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            _statCard(
              title: 'Products',
              value: '${inventory.products.length}',
              icon: Icons.inventory_2_outlined,
              color: AppColors.primary,
              isLoading: inventory.isLoading,
              onTap: () => switchTab(1),
            ),
            const SizedBox(height: AppSizes.md),

            _statCard(
              title: 'Low Stock Items',
              value: '${inventory.lowStockProducts.length}',
              icon: Icons.warning_amber_outlined,
              color: AppColors.warning,
              isLoading: inventory.isLoading,
              onTap: () => switchTab(1),
            ),
            const SizedBox(height: AppSizes.md),

            _statCard(
              title: 'Customers',
              value: '${customers.customers.length}',
              icon: Icons.people_outline,
              color: AppColors.info,
              isLoading: customers.isLoading,
              onTap: () => switchTab(2),
            ),
            const SizedBox(height: AppSizes.md),
            _statCard(
              title: 'Sells',
              value: '${orders.orders.length}',
              icon: Icons.receipt_long_outlined,
              color: AppColors.success,
              isLoading: orders.isLoading,
              onTap: () => switchTab(3),
            ),
            const SizedBox(height: AppSizes.md),
            _statCard(
              title: 'Stock Value',
              // ★ Changed $ to AED
              value: 'AED ${totalStockValue.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: AppColors.primaryDark,
              isLoading: inventory.isLoading,
              onTap: () => context.push('/home/stock-value'),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
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
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSizes.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  isLoading
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: color,
                            ),
                          ),
                        )
                      : Text(
                          value,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
