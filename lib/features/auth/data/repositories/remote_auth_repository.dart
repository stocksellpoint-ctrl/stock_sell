import '../datasources/auth_remote_datasource.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class RemoteAuthRepository implements AuthRepository {
  final AuthRemoteDataSource _api = AuthRemoteDataSource();

  @override
  Future<UserModel?> getCurrentUser() async {
    final data = await _api.getCurrentUser();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final data = await _api.login(email: email, password: password);
    final user = data['user'] as Map<String, dynamic>;
    return UserModel.fromJson(user);
  }

  @override
  Future<UserModel> register(String email, String password, String name) async {
    final data =
        await _api.register(name: name, email: email, password: password);
    final user = data['user'] as Map<String, dynamic>;
    return UserModel.fromJson(user);
  }

  @override
  Future<void> logout() => _api.logout();
}