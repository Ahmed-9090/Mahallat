import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../Domain/entites/StoresEntity.dart';

class StoreModel extends StoreEntity {
  static const List<String> validStoreTypes = [
    'Men Clothing',
    'Women Clothing',
    'Kids Clothing',
    'Men Shoes',
    'Women Shoes',
    'Kids Shoes',
    'Health And Beauty',
    'Bags',
  ];

  StoreModel({
    required String sellerId,
    required String storeId,
    required List<String> storeTypes,
    required String name,
    required String location,
    required String image,
    required String description,
    required List<String> categories,
    required LatLng storeLocation,
    String? phone,
    required StoreStatus status,
  }) : super(
         sellerId: sellerId,
         storeId: storeId,
         storeTypes: _normalizeStoreTypes(storeTypes),
         name: name,
         location: location,
         image: image,
         description: description,
         categories: categories,
         storeLocation: storeLocation,
         phone: phone,
         status: status,
       ) {
    _validateStoreTypes();
  }

  static List<String> _normalizeStoreTypes(List<String> types) {
    return types.map((type) {
      // Normalize variations to standard format
      if (type.toLowerCase().contains('health') &&
          type.toLowerCase().contains('beauty')) {
        return 'Health And Beauty';
      }
      if (type.toLowerCase().contains('health') &&
          type.toLowerCase().contains('care')) {
        return 'Health And Beauty';
      }
      return type;
    }).toList();
  }

  factory StoreModel.fromEntity(StoreEntity entity) {
    return StoreModel(
      sellerId: entity.sellerId,
      storeId: entity.storeId,
      storeTypes: entity.storeTypes,
      name: entity.name,
      location: entity.location,
      image: entity.image,
      description: entity.description,
      categories: entity.categories,
      storeLocation: entity.storeLocation,
      phone: entity.phone,
      status: entity.status,
    );
  }

  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    LatLng? storeLocation;
    if (data['storeLocation'] != null) {
      if (data['storeLocation'] is GeoPoint) {
        final geoPoint = data['storeLocation'] as GeoPoint;
        storeLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
      } else if (data['storeLocation'] is Map) {
        final locationMap = data['storeLocation'] as Map<String, dynamic>;
        storeLocation = LatLng(
          locationMap['latitude'] as double,
          locationMap['longitude'] as double,
        );
      }
    }

    return StoreModel(
      sellerId: data['sellerId'] ?? '',
      storeId: doc.id,
      storeTypes: List<String>.from(data['storeTypes'] ?? []),
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      image: data['image'] ?? '',
      description: data['description'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      storeLocation: storeLocation ?? const LatLng(32.0833, 36.1000), // Default to Al-Zarqa coordinates
      phone: data['phone'],
      status: StoreStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => StoreStatus.open,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'storeTypes': storeTypes,
      'name': name,
      'location': location,
      'image': image,
      'description': description,
      'categories': categories,
      'storeLocation': storeLocation != null ? {
        'latitude': storeLocation.latitude,
        'longitude': storeLocation.longitude,
      } : null,
      'phone': phone,
      'status': status.toString().split('.').last,
    };
  }

  void _validateStoreTypes() {
    if (storeTypes.isEmpty) {
      throw ArgumentError('At least one store type must be specified');
    }

    for (final type in storeTypes) {
      if (!validStoreTypes.contains(type)) {
        throw ArgumentError(
          'Invalid store type: $type. Valid types are: ${validStoreTypes.join(', ')}',
        );
      }
    }
  }

  String getPrimaryCollection() {
    if (storeTypes.isEmpty) return 'clothesMen';
    return storeTypes.first;
  }

  bool isForCategory(String category) {
    return storeTypes.contains(category);
  }

  StoreModel copyWith({
    String? sellerId,
    String? storeId,
    List<String>? storeTypes,
    String? name,
    String? location,
    String? image,
    String? description,
    List<String>? categories,
    LatLng? storeLocation,
    String? phone,
    StoreStatus? status,
  }) {
    return StoreModel(
      sellerId: sellerId ?? this.sellerId,
      storeId: storeId ?? this.storeId,
      storeTypes: storeTypes ?? this.storeTypes,
      name: name ?? this.name,
      location: location ?? this.location,
      image: image ?? this.image,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      storeLocation: storeLocation ?? this.storeLocation,
      phone: phone ?? this.phone,
      status: status ?? this.status,
    );
  }
}
