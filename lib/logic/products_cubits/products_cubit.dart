import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mahalattst2/logic/products_cubits/products_state.dart';
import '../../auth/Data/models/products_model.dart';
import '../../auth/Data/repos/clothes_repos/products_repo.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final ProductsRepository _repository;

  ProductsCubit(this._repository) : super(ProductsInitial());

  // Cache for storing loaded products by storeType
  final Map<String, List<ProductsModel>> _productsCache = {};

  Future<void> addProduct(ProductsModel product) async {
    emit(ProductsLoading());
    try {
      final productId = await _repository.addProduct(product);
      final newProduct = product.copyWith(productId: productId);

      // Update cache for the product's storeType
      final storeType = product.storeType;
      if (_productsCache.containsKey(storeType)) {
        _productsCache[storeType] = [..._productsCache[storeType]!, newProduct];
        emit(ProductsLoaded(_productsCache[storeType]!));
      }

      emit(ProductAddedSuccessfully('Product added successfully'));
    } catch (e) {
      emit(ProductsError('Failed to add product: ${e.toString()}'));
    }
  }

  Future<void> updateProduct(ProductsModel product) async {
    emit(ProductsLoading());
    try {
      await _repository.updateProduct(product);

      // Update cache for the product's storeType
      final storeType = product.storeType;
      if (_productsCache.containsKey(storeType)) {
        final index = _productsCache[storeType]!.indexWhere(
          (p) => p.productId == product.productId,
        );
        if (index != -1) {
          _productsCache[storeType]![index] = product;
          emit(ProductsLoaded(_productsCache[storeType]!));
        }
      }

      emit(ProductUpdatedSuccessfully('Product updated successfully'));
    } catch (e) {
      emit(ProductsError('Failed to update product: ${e.toString()}'));
    }
  }

  Future<void> deleteProduct(ProductsModel product) async {
    emit(ProductsLoading());
    try {
      await _repository.deleteProduct(product);

      // Update cache for the product's storeType
      final storeType = product.storeType;
      if (_productsCache.containsKey(storeType)) {
        _productsCache[storeType] =
            _productsCache[storeType]!
                .where((p) => p.productId != product.productId)
                .toList();
        emit(ProductsLoaded(_productsCache[storeType]!));
      }

      emit(ProductDeletedSuccessfully('Product deleted successfully'));
    } catch (e) {
      emit(ProductsError('Failed to delete product: ${e.toString()}'));
    }
  }

  Future<void> loadAllProducts(String storeType) async {
    emit(ProductsLoading());
    try {
      final products = await _repository.loadAllProducts(storeType);
      _productsCache[storeType] = products;
      emit(ProductsLoaded(products));
    } catch (e) {
      emit(ProductsError('Failed to load products: ${e.toString()}'));
    }
  }

  Future<void> loadProductsBySeller(String sellerId, String storeType) async {
    emit(ProductsLoading());
    try {
      // Validate storeType before proceeding
      if (storeType.isEmpty) {
        throw Exception('Please select a valid product category');
      }

      final products = await _repository.loadProductsBySeller(
        sellerId,
        storeType,
      );
      // Filter out archived products
      final activeProducts =
          products.where((product) => !product.isArchived).toList();
      _productsCache[storeType] = activeProducts;
      emit(ProductsLoaded(activeProducts));
    } on Exception catch (e) {
      emit(ProductsError(e.toString()));
    } catch (e) {
      emit(ProductsError('Failed to load products'));
    }
  }

  Stream<List<ProductsModel>> streamAllProducts(String storeType) {
    return _repository.getAllProducts(storeType).handleError((error) {
      emit(ProductsError('Error streaming products: ${error.toString()}'));
      return Stream.empty();
    });
  }

  Stream<List<ProductsModel>> streamProductsBySeller(
    String sellerId,
    String storeType,
  ) {
    return _repository.getProductsBySeller(sellerId, storeType).handleError((
      error,
    ) {
      emit(ProductsError('Error streaming products: ${error.toString()}'));
      return Stream.empty();
    });
  }

  List<ProductsModel>? getCachedProducts(String storeType) {
    return _productsCache[storeType];
  }

  // Helper method to get products by type
  List<ProductsModel>? getProductsByType(String storeType) {
    return _productsCache[storeType];
  }

  Future<void> deleteAllProductsForSeller(String sellerId, String storeType) async {
    emit(ProductsLoading());
    try {
      await _repository.deleteAllProductsForSeller(sellerId, storeType);
      
      // Clear the cache for this store type
      if (_productsCache.containsKey(storeType)) {
        _productsCache[storeType] = [];
        emit(ProductsLoaded([]));
      }
      
      emit(ProductDeletedSuccessfully('All store products deleted successfully'));
    } catch (e) {
      emit(ProductsError('Failed to delete store products: ${e.toString()}'));
    }
  }
}
