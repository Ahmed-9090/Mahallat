import '../../Domain/entites/products_entity.dart';
import '../models/stores_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductsModel extends ProductsEntity {
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final List<String> categories;
  final double? discount;
  final double? rating;
  final int? reviewCount;
  final String? productType;
  final String? typeInfo;
  final String? color;
  final String? size;
  final bool isArchived;

  ProductsModel({
    required String sellerId,
    required String productId,
    required String description,
    required List<String> images,
    required String name,
    required double price,
    required int stock,
    required String storeType,
    DateTime? createdAt,
    this.updatedAt,
    this.isActive = true,
    List<String>? categories,
    this.discount,
    this.rating,
    this.reviewCount,
    this.productType,
    this.typeInfo,
    this.color,
    this.size,
    this.isArchived = false,
  }) : createdAt = createdAt ?? DateTime.now(),
       categories = categories ?? [],
       super(
         sellerId: sellerId,
         productId: productId,
         description: description,
         images: images,
         name: name,
         price: price,
         stock: stock,
         storeType: storeType,
       ) {
    _validateStoreType();
  }

  void _validateStoreType() {
    if (!StoreModel.validStoreTypes.contains(storeType)) {
      throw ArgumentError(
        'Invalid store type: $storeType. Valid types are: ${StoreModel.validStoreTypes.join(', ')}',
      );
    }
  }

  @override
  ProductsModel copyWith({
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
    String? productType,
    String? typeInfo,
    String? color,
    String? size,
    bool? isArchived,
  }) {
    return ProductsModel(
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      description: description ?? this.description,
      images: images ?? this.images,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      storeType: storeType ?? this.storeType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      categories: categories ?? this.categories,
      discount: discount ?? this.discount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      productType: productType ?? this.productType,
      typeInfo: typeInfo ?? this.typeInfo,
      color: color ?? this.color,
      size: size ?? this.size,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'productId': productId,
      'description': description,
      'images': images,
      'name': name,
      'price': price,
      'stock': stock,
      'storeType': storeType,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'isActive': isActive,
      'categories': categories,
      'discount': discount,
      'rating': rating,
      'reviewCount': reviewCount,
      'productType': productType,
      'typeInfo': typeInfo,
      'color': color,
      'size': size,
      'isArchived': isArchived,
    };
  }

  factory ProductsModel.fromMap(Map<String, dynamic> map) {
    return ProductsModel(
      sellerId: map['sellerId'] ?? '',
      productId: map['productId'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      stock: (map['stock'] ?? 0).toInt(),
      storeType: map['storeType'] ?? '',
      createdAt:
          map['createdAt'] != null
              ? (map['createdAt'] is Timestamp
                  ? map['createdAt'].toDate()
                  : DateTime.fromMillisecondsSinceEpoch(map['createdAt']))
              : null,
      updatedAt:
          map['updatedAt'] != null
              ? (map['updatedAt'] is Timestamp
                  ? map['updatedAt'].toDate()
                  : DateTime.fromMillisecondsSinceEpoch(map['updatedAt']))
              : null,
      isActive: map['isActive'] ?? true,
      categories: List<String>.from(map['categories'] ?? []),
      discount: map['discount']?.toDouble(),
      rating: map['rating']?.toDouble(),
      reviewCount: map['reviewCount'],
      productType: map['productType'],
      typeInfo: map['typeInfo'],
      color: map['color'],
      size: map['size'],
      isArchived: map['isArchived'] == true,
    );
  }

  bool get isValidForAdd =>
      sellerId.isNotEmpty && name.isNotEmpty && images.isNotEmpty;

  bool get isValidForUpdate => isValidForAdd && productId.isNotEmpty;
}
