import '../../auth/Data/models/stores_model.dart';


class StoreState {}

final class StoreInitial extends StoreState {}

final class StoreLoading extends StoreState {}

final class StoreNotFound extends StoreState {}

final class StoresLoaded extends StoreState {
  final List<StoreModel> stores;
  StoresLoaded(this.stores);
}

final class StoreLoaded extends StoreState {
  final StoreModel store;
  StoreLoaded(this.store);
}

final class StoreOperationInProgress extends StoreState {}

final class StoreCreated extends StoreState {
  final String storeId;
  StoreCreated(this.storeId);
}

final class StoreUpdated extends StoreState {
  final StoreModel store;
  StoreUpdated(this.store);
}

final class StoreDeleted extends StoreState {}

final class StoreError extends StoreState {
  final String message;
  StoreError(this.message);
}