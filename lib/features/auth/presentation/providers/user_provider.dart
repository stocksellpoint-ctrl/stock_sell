import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repo;
  UserProvider(this._repo);

  List<UserModel> _users = [];
  bool _loading = false;
  String? _error;
  String? _deletingId;

  List<UserModel> get users => _users;
  bool get isLoading => _loading;
  String? get error => _error;
  String? get deletingId => _deletingId;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _repo.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _error = null;
    notifyListeners();
    try {
      final created = await _repo.create(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      _users = [created, ..._users];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(
    String id, {
    String? name,
    String? email,
    String? password,
    String? role,
    bool? isActive,
  }) async {
    _error = null;
    notifyListeners();
    try {
      final updated = await _repo.update(
        id,
        name: name,
        email: email,
        password: password,
        role: role,
        isActive: isActive,
      );
      _users = _users.map((u) => u.id == id ? updated : u).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleActive(String id, bool isActive) async {
    _deletingId = id;
    notifyListeners();
    try {
      return await update(id, isActive: isActive);
    } finally {
      _deletingId = null;
      notifyListeners();
    }
  }

  Future<bool> delete(String id) async {
    _deletingId = id;
    _error = null;
    notifyListeners();
    try {
      await _repo.delete(id);
      _users = _users.where((u) => u.id != id).toList();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _deletingId = null;
      notifyListeners();
    }
  }
}