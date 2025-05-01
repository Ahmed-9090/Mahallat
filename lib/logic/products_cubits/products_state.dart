import '../../auth/Data/models/products_model.dart';

abstract class ProductsState {
  const ProductsState();
}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<ProductsModel> products;
  const ProductsLoaded(this.products);

}

class ProductOperationSuccess extends ProductsState {
  final String message;
  const ProductOperationSuccess(this.message);

}

class ProductsError extends ProductsState {
  final String message;
  const ProductsError(this.message);
}
// Add these to your existing ProductsState
class ProductAddedSuccessfully extends ProductsState {
  final String message;
  ProductAddedSuccessfully(this.message);
}

class ProductUpdatedSuccessfully extends ProductsState {
  final String message;
  ProductUpdatedSuccessfully(this.message);
}

class ProductDeletedSuccessfully extends ProductsState {
  final String message;
  ProductDeletedSuccessfully(this.message);
}
