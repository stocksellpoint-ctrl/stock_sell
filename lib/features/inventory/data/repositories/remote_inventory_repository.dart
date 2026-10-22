import '../datasources/inventory_remote_datasource.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/product_model.dart';

class RemoteInventoryRepository implements InventoryRepository {
  final InventoryRemoteDataSource _api = InventoryRemoteDataSource();

  @override
  Future<List<ProductModel>> getAllProducts() => _api.getAll();

  @override
  Future<ProductModel?> getProductById(String id) async {
    final all = await _api.getAll();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ProductModel> createProduct(
    ProductModel product, {
    String? imagePath,
  }) =>
      _api.create(product, imagePath: imagePath);

  @override
  Future<ProductModel> updateProduct(
    ProductModel product, {
    String? imagePath,
  }) =>
      _api.update(product, imagePath: imagePath);

  @override
  Future<void> deleteProduct(String id) => _api.delete(id);

  @override
  Future<void> updateStock(String productId, int newQuantity) async {
    final product = await getProductById(productId);
    if (product == null) throw Exception('Product not found');
    await _api.update(product.copyWith(quantity: newQuantity));
  }
}