
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../features/inventory/data/models/product_model.dart';

class InventoryRemoteDataSource {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ProductModel>> getAll() async {
    try {
      final res = await _dio.get(ApiEndpoints.products);

      if (res.statusCode != 200) {
        throw ApiClient.instance.handleError(
          DioException(requestOptions: res.requestOptions, response: res),
        );
      }

      final body = res.data as Map<String, dynamic>;
      final items = body['data']['items'] as List;
      return items
          .map((j) => ProductModel.fromApiJson(j as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<ProductModel> create(
    ProductModel product, {
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': product.name,
        'sku': product.sku,
        'categoryId': product.categoryId,
        // ★ REMOVED: price
        'costPrice': product.costPrice.toString(),
        'quantity': product.quantity.toString(),
        'lowStockThreshold': product.lowStockThreshold.toString(),
        if (product.description != null && product.description!.isNotEmpty)
          'description': product.description!,
        if (imagePath != null && imagePath.isNotEmpty)
          'image': await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split('/').last,
          ),
      });

      final res = await _dio.post(
        ApiEndpoints.products,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = res.data as Map<String, dynamic>;
        return ProductModel.fromApiJson(
          body['data'] as Map<String, dynamic>,
        );
      }

      throw ApiClient.instance.handleError(
        DioException(requestOptions: res.requestOptions, response: res),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<ProductModel> update(
    ProductModel product, {
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': product.name,
        'sku': product.sku,
        'categoryId': product.categoryId,
        // ★ REMOVED: price
        'costPrice': product.costPrice.toString(),
        'quantity': product.quantity.toString(),
        'lowStockThreshold': product.lowStockThreshold.toString(),
        if (product.description != null && product.description!.isNotEmpty)
          'description': product.description!,
        if (imagePath != null && imagePath.isNotEmpty)
          'image': await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split('/').last,
          ),
      });

      final res = await _dio.put(
        ApiEndpoints.productById(product.id!),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (res.statusCode == 200) {
        final body = res.data as Map<String, dynamic>;
        return ProductModel.fromApiJson(
          body['data'] as Map<String, dynamic>,
        );
      }

      throw ApiClient.instance.handleError(
        DioException(requestOptions: res.requestOptions, response: res),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.productById(id));
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }
}