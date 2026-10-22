class RouteNames {
  RouteNames._();

  static const splash = '/';

  static const login = '/login';
  static const register = '/register';

  static const home = '/home';
  static const inventory = '/inventory';
  static const customers = '/customers';
  static const orders = '/orders';
  static const reports = '/reports';

  // sub-routes ( relative to their branch)
  static const productAdd = 'add';
  static const productDetail = ':id';
  static const customerAdd = 'add';
  static const orderDetails = ':id';
}
