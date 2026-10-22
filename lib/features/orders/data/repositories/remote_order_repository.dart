import '../datasources/order_remote_datasource.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';

class RemoteOrderRepository implements OrderRepository {
  final OrderRemoteDataSource _api = OrderRemoteDataSource();

  @override
  Future<List<OrderModel>> getAllOrders() => _api.getAll();

  @override
  Future<List<OrderModel>> getOrdersByCustomer(String customerId) async {
    final all = await _api.getAll();
    return all.where((o) => o.customerId == customerId).toList();
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    final all = await _api.getAll();
    try {
      return all.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<OrderModel> createOrder(OrderModel order) => _api.create(order);

  @override
  Future<OrderModel> updateOrderStatus(String id, String status) =>
      _api.updateStatus(id, status);

  @override
  Future<void> deleteOrder(String id) => _api.delete(id);
}