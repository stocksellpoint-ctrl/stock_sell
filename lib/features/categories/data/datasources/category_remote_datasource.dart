import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/category_model.dart';

class CategoryRemoteDataSource {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<CategoryModel>> getAll() async {
    try {
      final res = await _dio.get(ApiEndpoints.categories);
      final body = res.data as Map<String, dynamic>;
      final items = body['data']['items'] as List;
      return items
          .map((j) => CategoryModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<List<CategoryModel>> getTree() async {
    try {
      final res = await _dio.get(ApiEndpoints.categoryTree);
      final body = res.data as Map<String, dynamic>;
      final items = body['data']['items'] as List;
      return items
          .map((j) => CategoryModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<CategoryModel> create(CategoryModel category) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.categories,
        data: category.toJson(),
      );
      final body = res.data as Map<String, dynamic>;
      return CategoryModel.fromJson(body['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<CategoryModel> update(CategoryModel category) async {
    try {
      final res = await _dio.put(
        ApiEndpoints.categoryById(category.id),
        data: category.toJson(),
      );
      final body = res.data as Map<String, dynamic>;
      return CategoryModel.fromJson(body['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.categoryById(id));
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }
}
