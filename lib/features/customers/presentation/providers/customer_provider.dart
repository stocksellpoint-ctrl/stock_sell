import 'package:flutter/material.dart';
import 'package:stock_sell/features/customers/domain/repositories/customer_repository.dart';
import '../../data/models/customer_model.dart';


class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository;
  CustomerProvider(this._repository);

  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _customers = await _repository.getAllCustomers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCustomer(CustomerModel c) async {
    try {
      final created = await _repository.createCustomer(c);
      _customers.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(CustomerModel c) async {
    try {
      await _repository.updateCustomer(c);
      final idx = _customers.indexWhere((x) => x.id == c.id);
      if (idx != -1) _customers[idx] = c;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      await _repository.deleteCustomer(id);
      _customers.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}