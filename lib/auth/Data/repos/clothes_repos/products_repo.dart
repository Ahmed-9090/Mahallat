import '../../models/products_model.dart';

abstract class ProductsRepository {
  Future<String> addProduct(ProductsModel product);
  Future<void> updateProduct(ProductsModel product);
  Future<void> deleteProduct(ProductsModel product);
  Future<ProductsModel> getProduct(String productId, String storeType);
  Stream<List<ProductsModel>> getProductsBySeller(String sellerId, String storeType);
  Stream<List<ProductsModel>> getAllProducts(String storeType);
  Future<List<ProductsModel>> loadAllProducts(String storeType);
  Future<List<ProductsModel>> loadProductsBySeller(String sellerId, String storeType);
  Future<void> deleteAllProductsForSeller(String sellerId, String storeType);
}