import '../../data/models/product_model.dart';

abstract class InventoryRepository {
  Future<List<ProductModel>> getAllProducts();
  Future<ProductModel?> getProductById(String id);
  Future<ProductModel> createProduct(ProductModel product, {String? imagePath});
  Future<ProductModel> updateProduct(ProductModel product, {String? imagePath});
  Future<void> deleteProduct(String id);
  Future<void> updateStock(String productId, int newQuantity);
}