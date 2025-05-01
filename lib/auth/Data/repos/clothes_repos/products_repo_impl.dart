import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../utils/backend_endpoint.dart';
import '../../models/products_model.dart';
import 'products_repo.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final FirebaseFirestore _firestore;

  ProductsRepositoryImpl(this._firestore);

  String _getCollectionName(String storeType) {
    if (storeType.isEmpty) {
      throw Exception('Store type cannot be empty');
    }

    // Normalize the store type (remove spaces, special characters, lowercase)
    final normalizedType = storeType
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z]'), '');

    switch (normalizedType) {
      case 'menclothing':
        return BackendEndpoint.menClothes;
      case 'womenclothing':
        return BackendEndpoint.womenClothes;
      case 'kidsclothing':
        return BackendEndpoint.kidsClothes;
      case 'menshoes':
        return BackendEndpoint.menShoes;
      case 'womenshoes':
        return BackendEndpoint.womenShoes;
      case 'kidsshoes':
        return BackendEndpoint.kidsShoes;
      case 'healthandbeauty':
        return BackendEndpoint.healthAndCare;
      case 'bags':
        return BackendEndpoint.bags;
      default:
        throw Exception(
          'Invalid store type: $storeType. Valid types are: '
          'Men Clothing, Women Clothing, Kids Clothing, '
          'Men Shoes, Women Shoes, Kids Shoes, '
          'Health & Beauty, Bags',
        );
    }
  }

  @override
  Future<String> addProduct(ProductsModel product) async {
    try {
      if (!product.isValidForAdd) {
        throw Exception('Product is missing required fields');
      }

      final targetCollection = _getCollectionName(product.storeType);
      final docRef = _firestore.collection(targetCollection).doc();
      final productToSave = product.copyWith(productId: docRef.id);

      await docRef.set(productToSave.toMap());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Failed to add product: ${e.message}');
    } catch (e) {
      throw Exception('Failed to add product: ${e.toString()}');
    }
  }

  @override
  Future<void> updateProduct(ProductsModel product) async {
    try {
      if (!product.isValidForUpdate) {
        throw Exception('Product is missing required fields for update');
      }

      final targetCollection = _getCollectionName(product.storeType);
      await _firestore
          .collection(targetCollection)
          .doc(product.productId)
          .update(product.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Failed to update product: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update product: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProduct(ProductsModel product) async {
    try {
      if (product.productId.isEmpty) {
        throw Exception('Product ID cannot be empty');
      }

      final targetCollection = _getCollectionName(product.storeType);
      await _firestore
          .collection(targetCollection)
          .doc(product.productId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete product: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete product: ${e.toString()}');
    }
  }

  @override
  Future<ProductsModel> getProduct(String productId, String storeType) async {
    try {
      if (productId.isEmpty) {
        throw Exception('Product ID cannot be empty');
      }

      final targetCollection = _getCollectionName(storeType);
      final doc =
          await _firestore.collection(targetCollection).doc(productId).get();

      if (!doc.exists) {
        throw Exception('Product not found');
      }

      return ProductsModel.fromMap(doc.data()!);
    } on FirebaseException catch (e) {
      throw Exception('Failed to get product: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get product: ${e.toString()}');
    }
  }

  @override
  Stream<List<ProductsModel>> getProductsBySeller(
    String sellerId,
    String storeType,
  ) {
    if (sellerId.isEmpty) {
      throw Exception('Seller ID cannot be empty');
    }

    final targetCollection = _getCollectionName(storeType);
    return _firestore
        .collection(targetCollection)
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .handleError((error) {
          throw Exception('Failed to stream products: ${error.toString()}');
        })
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ProductsModel.fromMap(doc.data()))
                  .toList(),
        );
  }

  @override
  Stream<List<ProductsModel>> getAllProducts(String storeType) {
    final targetCollection = _getCollectionName(storeType);
    return _firestore
        .collection(targetCollection)
        .snapshots()
        .handleError((error) {
          throw Exception('Failed to stream products: ${error.toString()}');
        })
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ProductsModel.fromMap(doc.data()))
                  .toList(),
        );
  }

  @override
  Future<List<ProductsModel>> loadAllProducts(String storeType) async {
    try {
      final targetCollection = _getCollectionName(storeType);
      final snapshot = await _firestore.collection(targetCollection).get();
      return snapshot.docs
          .map((doc) => ProductsModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to load products: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load products: ${e.toString()}');
    }
  }

  @override
  Future<List<ProductsModel>> loadProductsBySeller(
    String sellerId,
    String storeType,
  ) async {
    try {
      if (sellerId.isEmpty) {
        throw Exception('Seller ID cannot be empty');
      }

      final targetCollection = _getCollectionName(storeType);
      final snapshot =
          await _firestore
              .collection(targetCollection)
              .where('sellerId', isEqualTo: sellerId)
              .get();

      return snapshot.docs
          .map((doc) => ProductsModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to load products: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load products: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAllProductsForSeller(String sellerId, String storeType) async {
    try {
      if (sellerId.isEmpty) {
        throw Exception('Seller ID cannot be empty');
      }

      final targetCollection = _getCollectionName(storeType);
      final snapshot = await _firestore
          .collection(targetCollection)
          .where('sellerId', isEqualTo: sellerId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete store products: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete store products: ${e.toString()}');
    }
  }
}
