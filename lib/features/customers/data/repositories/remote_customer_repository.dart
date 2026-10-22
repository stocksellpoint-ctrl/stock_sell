import '../datasources/customer_remote_datasource.dart';
import '../../domain/repositories/customer_repository.dart';
import '../models/customer_model.dart';

class RemoteCustomerRepository implements CustomerRepository {
  final CustomerRemoteDataSource _api = CustomerRemoteDataSource();

  @override
  Future<List<CustomerModel>> getAllCustomers() => _api.getAll();

  @override
  Future<CustomerModel?> getCustomerById(String id) async {
    final all = await _api.getAll();
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CustomerModel> createCustomer(CustomerModel customer) =>
      _api.create(customer);

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) =>
      _api.update(customer);

  @override
  Future<void> deleteCustomer(String id) => _api.delete(id);
}