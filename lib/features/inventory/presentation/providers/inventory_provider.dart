import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/inventory_repository.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository;
  InventoryProvider(this._repository);

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ProductModel> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _repository.getAllProducts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(ProductModel product, {String? imagePath}) async {
    try {
      final created = await _repository.createProduct(
        product,
        imagePath: imagePath,
      );
      _products.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product, {String? imagePath}) async {
    try {
      final updated = await _repository.updateProduct(
        product,
        imagePath: imagePath,
      );
      final idx = _products.indexWhere((p) => p.id == product.id);
      if (idx != -1) _products[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStock(String productId, int newQuantity) async {
    try {
      await _repository.updateStock(productId, newQuantity);
      final idx = _products.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        _products[idx] = _products[idx].copyWith(quantity: newQuantity);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}