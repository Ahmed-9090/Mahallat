import '../../../Domain/entites/StoresEntity.dart';
import '../../models/stores_model.dart';

abstract class StoreRepository {
  Future<List<StoreModel>> getStoresByType(List<String> storeTypes);
  Future<List<StoreModel>> getStoresByCategory(String category);
  Future<StoreModel> getStoreById(String storeId);
  Future<String> createStore(StoreEntity store);
  Future<void> updateStore(StoreEntity store);
  Future<void> deleteStore(String storeId);
  Future<List<StoreModel>> getStoresBySellerAndCategory(String sellerId, String category);
  Future<StoreModel?> getStoreBySellerAndCategory(String sellerId, String category);
}