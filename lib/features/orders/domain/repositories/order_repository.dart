import '../../data/models/order_model.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> getAllOrders();
  Future<List<OrderModel>> getOrdersByCustomer(String customerId);
  Future<OrderModel?> getOrderById(String id);
  Future<OrderModel> createOrder(OrderModel order);
  Future<OrderModel> updateOrderStatus(String id, String status);
  Future<void> deleteOrder(String id);
}