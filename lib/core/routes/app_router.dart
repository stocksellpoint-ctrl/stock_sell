

import 'package:go_router/go_router.dart';
import 'package:stock_sell/features/settings/presentation/screens/users_list_screen.dart';
import 'package:stock_sell/features/settings/presentation/screens/add_edit_user_screen.dart';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';

import '../../features/home/screens/main_shell_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/stock_value_screen.dart';

import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/inventory/presentation/screens/product_detail_screen.dart';
import '../../features/inventory/presentation/screens/add_edit_product_screen.dart';

// ★ Verify the file name — if your file is named customers_screen.dart
//    (plural), change the import below to match, otherwise the app
//    won't compile and the Customers branch won't register.
import '../../features/customers/presentation/screens/customer_screen.dart';
import '../../features/customers/presentation/screens/add_edit_customer_screen.dart';

import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/new_sale_screen.dart';

import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/report/presentation/screens/reports_screen.dart';

import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/appearance_screen.dart';
import '../../features/settings/presentation/screens/language_screen.dart';
import '../../features/settings/presentation/screens/user_screen.dart';

import 'route_names.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      // ─── Splash + Auth (no bottom nav) ─────────────────────
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(path: RouteNames.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: RouteNames.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // ─── Settings / Appearance / Account (top-level) ───────
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'appearance',
            builder: (_, __) => const AppearanceScreen(),
          ),
          GoRoute(path: 'language', builder: (_, __) => const LanguageScreen()),
          GoRoute(path: 'user', builder: (_, __) => const UserScreen()),
          GoRoute(
            path: 'users',
            builder: (_, __) => const UsersListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, __) => const AddEditUserScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (_, s) =>
                    AddEditUserScreen(userId: s.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),

      // ─── Main app shell (persistent bottom nav) ────────────
      //
      // Branch order MUST match the order in MainShellScreen:
      //   0 → Home
      //   1 → Inventory
      //   2 → Customers
      //   3 → Orders (Sales)
      //   4 → Reports
      //   5 → Settings (not in nav — reachable via drawer only)
      //
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // ── Branch 1: Home ─────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (_, __) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'categories',
                    builder: (_, __) => const CategoriesScreen(),
                  ),
                  GoRoute(
                    path: 'stock-value',
                    builder: (_, __) => const StockValueScreen(),
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 2: Inventory ────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.inventory,
                builder: (context, state) {
                  final filter = state.uri.queryParameters['filter'];
                  return InventoryScreen(filter: filter);
                },
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (_, __) => const AddEditProductScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (_, s) =>
                        AddEditProductScreen(productId: s.pathParameters['id']),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, s) =>
                        ProductDetailScreen(productId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 3: Customers ────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.customers,
                builder: (_, __) => const CustomersScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (_, __) => const AddEditCustomerScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (_, s) => AddEditCustomerScreen(
                      customerId: s.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 4: Orders ───────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.orders,
                builder: (_, __) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const NewSaleScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, s) =>
                        OrderDetailScreen(orderId: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 5: Reports ──────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.reports,
                builder: (_, __) => const ReportsScreen(),
              ),
            ],
          ),

          // ── Branch 6: Settings ─────────────────────────────
          // StatefulShellBranch(
          //   routes: [
          //     GoRoute(
          //       path: 'settings',
          //       builder: (_, __) => const SettingsScreen(),
          //       routes: [
          //         GoRoute(
          //           path: 'appearance',
          //           builder: (_, __) => const AppearanceScreen(),
          //         ),
          //         GoRoute(
          //           path: 'user',
          //           builder: (_, __) => const UserScreen(),
          //         ),
          //       ],
          //     ),
          //   ],
          // ),
        ],
      ),
    ],
  );
}
