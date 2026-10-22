import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';
import '../../domain/repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository;
  OrderProvider(this._repository);

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _repository.getAllOrders();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder(OrderModel order) async {
    try {
      final created = await _repository.createOrder(order);
      _orders.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrder(String id) async {
  try {
    await _repository.deleteOrder(id);
    _orders.removeWhere((o) => o.id == id);
    notifyListeners();
    return true;
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    return false;
  }
}

  Future<bool> updateStatus(String id, String status) async {
    try {
      final updated = await _repository.updateOrderStatus(id, status);
      final idx = _orders.indexWhere((o) => o.id == id);
      if (idx != -1) _orders[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}