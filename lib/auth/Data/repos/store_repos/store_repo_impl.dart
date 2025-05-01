import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/backend_endpoint.dart';
import '../../../Domain/entites/StoresEntity.dart';
import '../../models/stores_model.dart';

import 'store_repo.dart';

class StoreRepositoryImpl implements StoreRepository {
  final FirebaseFirestore _firestore;

  StoreRepositoryImpl(this._firestore);

  @override
  Future<List<StoreModel>> getStoresByType(List<String> storeTypes) async {
    final snapshot = await _firestore.collection(BackendEndpoint.basePath)
        .where('storeTypes', arrayContainsAny: storeTypes)
        .get();
    return snapshot.docs.map((doc) => StoreModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<StoreModel>> getStoresByCategory(String category) async {
    final snapshot = await _firestore.collection(BackendEndpoint.basePath)
        .where('categories', arrayContains: category)
        .get();
    return snapshot.docs.map((doc) => StoreModel.fromFirestore(doc)).toList();
  }

  @override
  Future<StoreModel> getStoreById(String storeId) async {
    final doc = await _firestore.doc(BackendEndpoint.getStore(storeId)).get();
    return StoreModel.fromFirestore(doc);
  }

  @override
  Future<String> createStore(StoreEntity store) async {
    try {
      final storeModel = StoreModel.fromEntity(store);
      final storeDoc = _firestore.collection('stores').doc();
      final storeData = {
        'sellerId': storeModel.sellerId,
        'storeId': storeDoc.id,
        'storeTypes': storeModel.storeTypes,
        'name': storeModel.name,
        'location': storeModel.location,
        'image': storeModel.image,
        'description': storeModel.description,
        'categories': storeModel.categories,
        'phone': storeModel.phone,
        'storeLocation': GeoPoint(
          storeModel.storeLocation.latitude,
          storeModel.storeLocation.longitude,
        ),
        'status': storeModel.status.toString().split('.').last,
      };
      await storeDoc.set(storeData);
      return storeDoc.id;
    } catch (e) {
      throw Exception('Failed to create store: $e');
    }
  }

  @override
  Future<void> updateStore(StoreEntity store) async {
    try {
      final storeModel = StoreModel.fromEntity(store);
      final storeDoc = _firestore.collection('stores').doc(storeModel.storeId);
      final storeData = {
        'name': storeModel.name,
        'location': storeModel.location,
        'image': storeModel.image,
        'description': storeModel.description,
        'phone': storeModel.phone,
        'storeLocation': GeoPoint(
          storeModel.storeLocation.latitude,
          storeModel.storeLocation.longitude,
        ),
        'status': storeModel.status.toString().split('.').last,
      };
      await storeDoc.update(storeData);
    } catch (e) {
      throw Exception('Failed to update store: $e');
    }
  }

  @override
  Future<void> deleteStore(String storeId) async {
    await _firestore.doc(BackendEndpoint.getStore(storeId)).delete();
  }

  @override
  Future<List<StoreModel>> getStoresBySellerAndCategory(String sellerId, String category) async {
    final snapshot = await _firestore.collection(BackendEndpoint.basePath)
        .where('sellerId', isEqualTo: sellerId)
        .get();

    return snapshot.docs.map((doc) => StoreModel.fromFirestore(doc)).toList();
  }

  Future<StoreModel?> getStoreBySellerAndCategory(String sellerId, String category) async {
    final snapshot = await _firestore.collection(BackendEndpoint.basePath)
        .where('sellerId', isEqualTo: sellerId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return StoreModel.fromFirestore(snapshot.docs.first);
  }
}