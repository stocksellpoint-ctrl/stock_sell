// import 'package:flutter/material.dart';

// import 'package:provider/provider.dart';

// import 'package:stock_sell/core/di/service_locator.dart';

// import 'core/routes/app_router.dart';
// import 'core/theme/app_theme.dart';

// // Repositories (concrete mock implementations)
// // import 'features/auth/data/repositories/auth_repository_impl.dart';
// import 'package:stock_sell/features/auth/domain/repositories/auth_repository.dart';
// import 'features/auth/presentation/providers/auth_provider.dart';

// // import 'features/inventory/data/repositories/product_repository_impl.dart';
// import 'package:stock_sell/features/inventory/domain/repositories/inventory_repository.dart';
// import 'features/inventory/presentation/providers/inventory_provider.dart';

// // import 'features/customers/data/repositories/customer_repository_impl.dart';
// import 'package:stock_sell/features/customers/domain/repositories/customer_repository.dart';
// import 'features/customers/presentation/providers/customer_provider.dart';

// // import 'features/orders/data/repositories/order_repository_impl.dart';
// import 'package:stock_sell/features/orders/domain/repositories/order_repository.dart';
// import 'features/orders/presentation/providers/order_provider.dart';

// import 'features/categories/presentation/providers/category_provider.dart';

// import 'features/report/presentation/providers/report_provider.dart';

// class InventoryApp extends StatelessWidget {
//   const InventoryApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp.router(
//       title: 'Stock & Sell',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.light,
//       routerConfig: AppRouter.router,
//       builder: (context, child) {
//         return MultiProvider(
//           providers: [
//             ...ServiceLocator.providers,
//             // Each provider constructs its own repository instance.
//             // No cross-provider dependencies → no ordering issues.

//             // ChangeNotifierProvider(
//             //   create: (_) => AuthProvider(AuthRepositoryImpl()),
//             // ),
//             // ChangeNotifierProvider(
//             //   create: (_) => InventoryProvider(InventoryRepositoryImpl()),
//             // ),
//             // ChangeNotifierProvider(
//             //   create: (_) => CustomerProvider(CustomerRepositoryImpl()),
//             // ),
//             // ChangeNotifierProvider(
//             //   create: (_) => OrderProvider(OrderRepositoryImpl()),
//             // ),

//             // ── Feature providers (read from ServiceLocator) ─
//             ChangeNotifierProvider(
//               create: (ctx) => AuthProvider(ctx.read<AuthRepository>()),
//             ),
//             ChangeNotifierProvider(
//               create: (ctx) =>
//                   InventoryProvider(ctx.read<InventoryRepository>()),
//             ),
//             ChangeNotifierProvider(
//               create: (ctx) => CustomerProvider(ctx.read<CustomerRepository>()),
//             ),
//             ChangeNotifierProvider(
//               create: (ctx) => OrderProvider(ctx.read<OrderRepository>()),
//             ),

//             ChangeNotifierProvider(create: (ctx) => CategoryProvider()),

//             ChangeNotifierProvider(create: (_) => ReportProvider()),
//           ],
//           child: child ?? const SizedBox.shrink(),
//         );
//       },
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:stock_sell/core/di/service_locator.dart';
import 'package:stock_sell/features/auth/data/repositories/user_repository.dart';
import 'package:stock_sell/features/auth/presentation/providers/user_provider.dart';

import 'core/routes/app_router.dart';

// Repositories
import 'package:stock_sell/features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

import 'package:stock_sell/features/inventory/domain/repositories/inventory_repository.dart';
import 'features/inventory/presentation/providers/inventory_provider.dart';

import 'package:stock_sell/features/customers/domain/repositories/customer_repository.dart';
import 'features/customers/presentation/providers/customer_provider.dart';

import 'package:stock_sell/features/orders/domain/repositories/order_repository.dart';
import 'features/orders/presentation/providers/order_provider.dart';

import 'features/categories/presentation/providers/category_provider.dart';
import 'features/report/presentation/providers/report_provider.dart';

import 'features/settings/presentation/providers/settings_provider.dart';

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch settings so MaterialApp rebuilds on theme/locale change.
    final settings = context.watch<SettingsProvider>();

    return MaterialApp.router(
      title: 'Stock & Sell',
      debugShowCheckedModeBanner: false,

      // ── Theme from settings ─────────────────────────────
      theme: _buildTheme(settings.seedColor, Brightness.light),
      darkTheme: _buildTheme(settings.seedColor, Brightness.dark),
      themeMode: settings.themeMode,

      // ── Locale from settings ────────────────────────────
      locale: settings.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      routerConfig: AppRouter.router,

      builder: (context, child) {
        return MultiProvider(
          providers: [
            ...ServiceLocator.providers,

            // Feature providers — read repositories from ServiceLocator
            ChangeNotifierProvider(
              create: (ctx) => AuthProvider(ctx.read<AuthRepository>()),
            ),
            ChangeNotifierProvider(
              create: (ctx) =>
                  InventoryProvider(ctx.read<InventoryRepository>()),
            ),
            ChangeNotifierProvider(
              create: (ctx) =>
                  CustomerProvider(ctx.read<CustomerRepository>()),
            ),
            ChangeNotifierProvider(
              create: (ctx) => OrderProvider(ctx.read<OrderRepository>()),
            ),
            ChangeNotifierProvider(create: (_) => CategoryProvider()),
            ChangeNotifierProvider(create: (_) => ReportProvider()),

            // inside MultiProvider, alongside the other ChangeNotifierProviders:
            ChangeNotifierProvider(
              create: (_) => UserProvider(UserRepository()),
            ),
          ],
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  /// Central theme builder — same as your old `AppTheme.light` but
  /// parameterised by seed color + brightness so both themes and any
  /// user-chosen accent color derive consistently.
  ThemeData _buildTheme(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: scheme.surfaceContainerHighest,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.grey.shade100
            : Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      // Add more app-wide defaults here if needed.
    );
  }
}