import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../features/orders/data/models/order_model.dart';

class OrderRemoteDataSource {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<OrderModel>> getAll() async {
    try {
      final res = await _dio.get(ApiEndpoints.orders);
      final body = res.data as Map<String, dynamic>;
      final items = body['data']['items'] as List;
      return items
          .map((j) => OrderModel.fromApiJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<OrderModel> create(OrderModel order) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.orders,
        data: order.toApiJson(),
      );
      final body = res.data as Map<String, dynamic>;
      return OrderModel.fromApiJson(body['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<OrderModel> updateStatus(String id, String status) async {
    try {
      final res = await _dio.patch(
        ApiEndpoints.orderStatus(id),
        data: {'status': status},
      );
      final body = res.data as Map<String, dynamic>;
      return OrderModel.fromApiJson(body['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.orderById(id));
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }
}