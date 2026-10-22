import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../features/report/data/models/inventory_report_model.dart';
import '../../../../features/report/data/models/profit_report_model.dart';

class ReportRemoteDataSource {
  final Dio _dio = ApiClient.instance.dio;

  Future<InventoryReportModel> inventoryReport() async {
    try {
      final res = await _dio.get(ApiEndpoints.inventoryReport);
      if (res.statusCode == 200) {
        return InventoryReportModel.fromJson(
          (res.data as Map<String, dynamic>)['data']
              as Map<String, dynamic>,
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

  Future<ProfitReportModel> profitReport({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.profitReport,
        queryParameters: {
          'from': _formatDate(from),
          'to': _formatDate(to),
        },
      );
      if (res.statusCode == 200) {
        return ProfitReportModel.fromJson(
          (res.data as Map<String, dynamic>)['data']
              as Map<String, dynamic>,
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

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}