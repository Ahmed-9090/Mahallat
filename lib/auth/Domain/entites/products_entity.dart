import '../../Data/models/products_model.dart';

abstract class ProductsEntity {
  final String sellerId;
  final String productId;
  final String description;
  final List<String> images;
  final String name;
  final double price;
  final int stock;
  final String storeType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final List<String> categories;
  final double? discount;
  final double? rating;
  final int? reviewCount;

  ProductsEntity({
    required this.sellerId,
    required this.productId,
    required this.description,
    required this.images,
    required this.name,
    required this.price,
    required this.stock,
    required this.storeType,
    DateTime? createdAt,
    this.updatedAt,
    this.isActive = true,
    List<String>? categories,
    this.discount,
    this.rating,
    this.reviewCount,
  }) : createdAt = createdAt ?? DateTime.now(),
       categories = categories ?? [];

  // Calculated getters
  double get discountedPrice => discount != null
      ? price * (1 - discount!)
      : price;

  bool get isInStock => stock > 0;
  bool get isNew => DateTime.now().difference(createdAt).inDays < 7;
  bool get isPopular => (rating ?? 0) >= 4.0 && (reviewCount ?? 0) > 10;

  // Copy with method
  ProductsEntity copyWith({
    String? sellerId,
    String? productId,
    String? description,
    List<String>? images,
    String? name,
    double? price,
    int? stock,
    String? storeType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<String>? categories,
    double? discount,
    double? rating,
    int? reviewCount,
  });

  // Serialization
  Map<String, dynamic> toMap();

  // Deserialization
  factory ProductsEntity.fromMap(Map<String, dynamic> map) {
    return ProductsModel(
      sellerId: map['sellerId'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      images: List<String>.from(map['images'] as List<dynamic>? ?? []),
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as int?) ?? 0,
      storeType: map['storeType'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
      isActive: map['isActive'] as bool? ?? true,
      categories: List<String>.from(map['categories'] as List<dynamic>? ?? []),
      discount: (map['discount'] as num?)?.toDouble(),
      rating: (map['rating'] as num?)?.toDouble(),
      reviewCount: map['reviewCount'] as int?,
    );
  }

  // Validation
  bool get isValidForAdd =>
      sellerId.isNotEmpty &&
          name.isNotEmpty &&
          images.isNotEmpty &&
          price > 0;

  bool get isValidForUpdate =>
      isValidForAdd &&
          productId.isNotEmpty;

  // Equality comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ProductsEntity &&
              runtimeType == other.runtimeType &&
              productId == other.productId &&
              sellerId == other.sellerId;

  @override
  int get hashCode => productId.hashCode ^ sellerId.hashCode;

  // String representation
  @override
  String toString() {
    return 'Products{'
        'sellerId: $sellerId, '
        'productId: $productId, '
        'name: $name, '
        'price: $price, '
        'stock: $stock'
        '}';
  }
}