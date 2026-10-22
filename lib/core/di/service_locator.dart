import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// import 'package:stock_sell/features/inventory/data/repositories/product_repository_impl.dart';

// import '../../features/auth/domain/repositories/auth_repository.dart';
// import '../../features/auth/data/repositories/auth_repository_impl.dart';

// import '../../features/inventory/domain/repositories/inventory_repository.dart';

// import '../../features/customers/domain/repositories/customer_repository.dart';
// import '../../features/customers/data/repositories/customer_repository_impl.dart';

// import '../../features/orders/domain/repositories/order_repository.dart';
// import '../../features/orders/data/repositories/order_repository_impl.dart';



// Interfaces
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/customers/domain/repositories/customer_repository.dart';
import '../../features/orders/domain/repositories/order_repository.dart';



// Remote implementations (USE THESE NOW)
import '../../features/auth/data/repositories/remote_auth_repository.dart';
import '../../features/inventory/data/repositories/remote_inventory_repository.dart';
import '../../features/customers/data/repositories/remote_customer_repository.dart';
import '../../features/orders/data/repositories/remote_order_repository.dart';



// Mock implementations (fallback — kept for offline work)
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/inventory/data/repositories/product_repository_impl.dart';
import '../../features/customers/data/repositories/customer_repository_impl.dart';
import '../../features/orders/data/repositories/order_repository_impl.dart';

class ServiceLocator {
  ServiceLocator._();

  static const bool useRemote = true;

  static List<SingleChildWidget> get providers => [
    Provider<AuthRepository>(
      create: (_) =>  useRemote 
        ? RemoteAuthRepository() 
        : AuthRepositoryImpl()
    ),
    Provider<InventoryRepository>(
      create: (_) =>  useRemote 
        ? RemoteInventoryRepository() 
        : InventoryRepositoryImpl()
    ),
    Provider<CustomerRepository>(
      create: (_) =>  useRemote 
        ? RemoteCustomerRepository() 
        : CustomerRepositoryImpl()
    ),
    Provider<OrderRepository>(
      create: (_) => useRemote 
        ? RemoteOrderRepository() 
        : OrderRepositoryImpl()
    ),
  ];
}
