import 'package:flutter/material.dart';
import 'package:stock_sell/core/network/api_exception.dart';

import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository);

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // -------- Getters--------------------
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // ─── Helpers ─────────────────────────────────────────────────
  /// Safe `notifyListeners` — guards against calling it after dispose.
  void _safeNotify() {
    if (hasListeners) notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      _safeNotify();
    }
  }

  // ─── Auth status check (used at app start / route guard) ─────
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _safeNotify();

    try {
      _user = await _repository.getCurrentUser();
    } catch (e) {
      // Not being able to read a cached session is not a fatal error —
      // treat the user as logged out, but keep a debug trace.
      debugPrint('checkAuthStatus failed: $e');
      _user = null;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  // ─── Login ───────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _user = await _repository.login(email, password);
      return true;
    } on ApiException catch (e) {
      _error = e.friendlyMessage;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  // ─── Register ────────────────────────────────────────────────
  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _user = await _repository.register(email, password, name);
      return true;
    } on ApiException catch (e) {
      _error = e.friendlyMessage;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  // ─── Logout ──────────────────────────────────────────────────
  /// Clears the local session regardless of whether the repository call
  /// succeeds. This avoids the drawer getting stuck on a network error
  /// while trying to log out
  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (e) {
      debugPrint('logout repository call failed (ignored): $e');
    }

    _user = null;
    _error = null;
    _isLoading = false;
    _safeNotify();
  }
}
