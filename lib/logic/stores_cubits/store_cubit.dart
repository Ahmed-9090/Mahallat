import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/Data/repos/store_repos/store_repo.dart';
import '../../auth/Domain/entites/StoresEntity.dart';
import 'store_state.dart';
import '../../auth/Data/models/stores_model.dart';

class StoreCubit extends Cubit<StoreState> {
  final StoreRepository _repository;

  StoreCubit(this._repository) : super(StoreInitial());

  // Load multiple stores by type (men/women/kids)
  Future<void> loadStoresByType(List<String> storeTypes) async {
    emit(StoreLoading());
    try {
      final stores = await _repository.getStoresByType(storeTypes);
      emit(StoresLoaded(stores));
    } catch (e) {
      emit(StoreError(e.toString()));
      rethrow;
    }
  }

  // Load multiple stores by category (shoes/bags/etc)
  Future<void> loadStoresByCategory(String category) async {
    emit(StoreLoading());
    try {
      final stores = await _repository.getStoresByCategory(category);
      emit(StoresLoaded(stores));
    } catch (e) {
      emit(StoreError(e.toString()));
      rethrow;
    }
  }

  // Load single store by ID
  Future<void> loadStoreById(String storeId) async {
    emit(StoreLoading());
    try {
      final store = await _repository.getStoreById(storeId);
      emit(StoreLoaded(store));
    } catch (e) {
      emit(StoreError(e.toString()));
      rethrow;
    }
  }

  Future<void> loadStoreBySellerAndCategory(String sellerId, String category) async {
    emit(StoreLoading());
    try {
      final store = await _repository.getStoreBySellerAndCategory(sellerId, category);
      if (store != null) {
        emit(StoreLoaded(store));
      } else {
        emit(StoreNotFound());
      }
    } catch (e) {
      emit(StoreError(e.toString()));
    }
  }

  // Create new store
  Future<void> createStore(StoreModel store) async {
    emit(StoreOperationInProgress());
    try {
      final storeId = await _repository.createStore(store);
      emit(StoreCreated(storeId));
      await loadStoreBySellerAndCategory(store.sellerId, store.storeTypes.first);
    } catch (e) {
      emit(StoreError(e.toString()));
    }
  }

  Future<void> updateStore(StoreModel store) async {
    try {
      emit(StoreLoading());
      await _repository.updateStore(StoreEntity(
        storeId: store.storeId,
        sellerId: store.sellerId,
        name: store.name,
        location: store.location,
        description: store.description,
        image: store.image,
        storeLocation: store.storeLocation,
        storeTypes: store.storeTypes,
        categories: store.categories,
        status: store.status,
      ));
      emit(StoreUpdated(store));
      await loadStoreBySellerAndCategory(store.sellerId, store.storeTypes.first);
    } catch (e) {
      emit(StoreError(e.toString()));
    }
  }

  Future<void> deleteStore(String storeId) async {
    emit(StoreOperationInProgress());
    try {
      final store = await _repository.getStoreById(storeId);
      await _repository.deleteStore(storeId);
      emit(StoreDeleted());
      await loadStoreBySellerAndCategory(store.sellerId, store.storeTypes.first);
    } catch (e) {
      emit(StoreError(e.toString()));
    }
  }

  // Reset to initial state
  void resetToInitial() => emit(StoreInitial());
}