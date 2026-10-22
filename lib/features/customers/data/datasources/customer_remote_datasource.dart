import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../features/customers/data/models/customer_model.dart';

class CustomerRemoteDataSource {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<CustomerModel>> getAll() async {
    try {
      final res = await _dio.get(ApiEndpoints.customers);
      final body = res.data as Map<String, dynamic>;
      final items = body['data']['items'] as List;
      return items
          .map((j) => CustomerModel.fromApiJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<CustomerModel> create(CustomerModel customer) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.customers,
        data: customer.toApiJson(),
      );
      final body = res.data as Map<String, dynamic>;
      return CustomerModel.fromApiJson(body['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<CustomerModel> update(CustomerModel customer) async {
    try {
      final res = await _dio.put(
        ApiEndpoints.customerById(customer.id!),
        data: customer.toApiJson(),
      );
      final body = res.data as Map<String, dynamic>;
      return CustomerModel.fromApiJson(body['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.customerById(id));
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }
}