import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Mock implementation — swap for Remote when backend is ready.
class AuthRepositoryImpl implements AuthRepository {
  UserModel? _currentUser;

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    _currentUser = UserModel(
      id: 'mock-user-1',
      email: email,
      name: email.split('@').first,
      role: 'admin',
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> register(
      String email, String password, String name) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = UserModel(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name,
      role: 'admin',
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }
}