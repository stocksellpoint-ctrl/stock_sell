import 'package:flutter/material.dart';

import '../../data/datasources/category_remote_datasource.dart';
import '../../data/models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRemoteDataSource _api = CategoryRemoteDataSource();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Only top-level categories (parentId == null)
  List<CategoryModel> get parents =>
      _categories.where((c) => c.isParent).toList();

  /// Children of a given parent id
  List<CategoryModel> childrenOf(String parentId) =>
      _categories.where((c) => c.parentId == parentId).toList();

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await _api.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(CategoryModel category) async {
    try {
      final created = await _api.create(category);
      _categories.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(CategoryModel category) async {
    try {
      final updated = await _api.update(category);
      final idx = _categories.indexWhere((c) => c.id == category.id);
      if (idx != -1) _categories[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      await _api.delete(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
