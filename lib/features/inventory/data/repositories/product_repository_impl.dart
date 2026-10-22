import '../../../../shared/mock_data.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/product_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final List<ProductModel> _products = List.from(MockData.products);
  int _idCounter = 1000;

  @override
  Future<List<ProductModel>> getAllProducts() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_products);
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ProductModel> createProduct(
    ProductModel product, {
    String? imagePath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final created = product.copyWith(
      id: 'p${_idCounter++}',
      imageUrl: imagePath, // local path used as URL in mock mode
    );
    _products.add(created);
    return created;
  }

  @override
  Future<ProductModel> updateProduct(
    ProductModel product, {
    String? imagePath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _products.indexWhere((p) => p.id == product.id);
    final updated = imagePath != null
        ? product.copyWith(imageUrl: imagePath)
        : product;
    if (idx != -1) _products[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _products.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> updateStock(String productId, int newQuantity) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx] = _products[idx].copyWith(quantity: newQuantity);
    }
  }
}
