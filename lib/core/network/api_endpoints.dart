/// All endpoint paths

class ApiEndpoints {
  ApiEndpoints._();

  // ★ CHANGE THIS when you deploy a new backend or test on a physical device
  //   - Android emulator: http://10.0.2.2:5000/api/v1
  //   - iOS simulator:    http://localhost:5000/api/v1
  //   - Physical device:  http://<your-pc-lan-ip>:5000/api/v1
  //   - Production:       https://your-project.vercel.app/api/v1
  static const String baseUrl =
      'https://stock-sell-point-backend.vercel.app/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Categories
  static const String categories = '/categories';
  static const String categoryTree = '/categories/tree';
  static String categoryById(String id) => '/categories/$id';

  // Products
  static const String products = '/products';
  static String productById(String id) => '/products/$id';

  // Customers
  static const String customers = '/customers';
  static String customerById(String id) => '/customers/$id';

  // Sells
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';

  // ═══════════════════════════════════════════════════════════
  // Reports
  // ═══════════════════════════════════════════════════════════

  /// Current inventory snapshot: stock value, cost value,
  /// potential profit, low stock, value by category.
  static const String inventoryReport = '/reports/inventory';

  /// Profit report for a date range.
  /// Requires `?from=YYYY-MM-DD&to=YYYY-MM-DD` query params.
  static const String profitReport = '/reports/profit';

  /// users
  static const String users = '/users';
}
