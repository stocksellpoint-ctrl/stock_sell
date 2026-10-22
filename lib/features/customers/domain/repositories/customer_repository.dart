import '../../data/models/customer_model.dart';

abstract class CustomerRepository {
  Future<List<CustomerModel>> getAllCustomers();
  Future<CustomerModel?> getCustomerById(String id);
  Future<CustomerModel> createCustomer(CustomerModel customer);
  Future<CustomerModel> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
}