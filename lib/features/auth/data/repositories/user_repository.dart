import 'package:stock_sell/core/network/api_client.dart';
import 'package:stock_sell/core/network/api_endpoints.dart';
import 'package:stock_sell/features/auth/data/models/user_model.dart';



class UserRepository {
  final _client = ApiClient.instance;

  Future<List<UserModel>> list() async {
    try {
      final res = await _client.dio.get(ApiEndpoints.users);
      final data = res.data['data'];
      final items = (data['items'] as List?) ?? [];
      return items
          .map((j) => UserModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _client.handleError(e);
    }
  }

  Future<UserModel> create({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final res = await _client.dio.post(
        ApiEndpoints.users,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw _client.handleError(e);
    }
  }

  Future<UserModel> update(
    String id, {
    String? name,
    String? email,
    String? password,
    String? role,
    bool? isActive,
  }) async {
    try {
      final res = await _client.dio.put(
        '${ApiEndpoints.users}/$id',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
          if (role != null) 'role': role,
          if (isActive != null) 'isActive': isActive,
        },
      );
      return UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw _client.handleError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.dio.delete('${ApiEndpoints.users}/$id');
    } catch (e) {
      throw _client.handleError(e);
    }
  }
}