import 'package:stock_sell/features/customers/domain/repositories/customer_repository.dart';

import '../../../../shared/mock_data.dart';

import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final List<CustomerModel> _customers = List.from(MockData.customers);
  int _idCounter = 1000;

  @override
  Future<List<CustomerModel>> getAllCustomers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_customers);
  }

  @override
  Future<CustomerModel?> getCustomerById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final created = customer.copyWith(id: 'c${_idCounter++}');
    _customers.add(created);
    return created;
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) _customers[idx] = customer;
    return customer;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _customers.removeWhere((c) => c.id == id);
  }
}