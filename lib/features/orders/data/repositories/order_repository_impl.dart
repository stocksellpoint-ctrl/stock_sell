import '../../../../shared/mock_data.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final List<OrderModel> _orders = List.from(MockData.orders);
  int _idCounter = 1000;

  @override
  Future<List<OrderModel>> getAllOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final sorted = List<OrderModel>.from(_orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<List<OrderModel>> getOrdersByCustomer(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _orders.where((o) => o.customerId == customerId).toList();
  }

  @override
  Future<OrderModel?> getOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final created = OrderModel(
      id: 'o${_idCounter++}',
      customerId: order.customerId,
      customerName: order.customerName,
      items: order.items,
      total: order.total,
      status: order.status,
      createdAt: DateTime.now(),
    );
    _orders.add(created);
    return created;
  }

  @override
  Future<OrderModel> updateOrderStatus(String id, String status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx != -1) {
      final o = _orders[idx];
      _orders[idx] = OrderModel(
        id: o.id, customerId: o.customerId, customerName: o.customerName,
        items: o.items, total: o.total, status: status,
        createdAt: o.createdAt,
      );
      return _orders[idx];
    }
    throw Exception('Order not found');
  }

  @override
  Future<void> deleteOrder(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _orders.removeWhere((o) => o.id == id);
  }
}