
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../inventory/presentation/providers/inventory_provider.dart';

class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Consumer<InventoryProvider>(
        builder: (context, inventory, _) {
          final lowStockCount = inventory.lowStockProducts.length;
          final hasLowStock = lowStockCount > 0;

          return NavigationBar(
            // ★ selectedIndex clamps to the number of destinations — if the
            //   current branch is 5 (Settings), we fall back to Home so the
            //   nav bar doesn't try to highlight a non-existent tab.
            selectedIndex: navigationShell.currentIndex < 5
                ? navigationShell.currentIndex
                : 0,
            onDestinationSelected: _onTap,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: hasLowStock,
                  label: Text('$lowStockCount'),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.inventory_2_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: hasLowStock,
                  label: Text('$lowStockCount'),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.inventory_2),
                ),
                label: 'Inventory',
              ),
              // ★ This is branch index 2 in the router — Customers
              const NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Customers',
              ),
              // ★ Branch index 3 in the router — Orders / Sales
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Sales',
              ),
              // ★ Branch index 4 in the router — Reports
              const NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Reports',
              ),
            ],
          );
        },
      ),
    );
  }
}