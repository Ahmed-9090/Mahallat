import 'package:google_maps_flutter/google_maps_flutter.dart';

enum StoreStatus {
  open,
  closed,
  busy
}

class StoreEntity {
  final String sellerId;
  final String storeId;
  final List<String> storeTypes;
  final String name;
  final String location;
  final String image;
  final String description;
  final List<String> categories;
  final String? phone;
  final StoreStatus status;
  LatLng storeLocation;

  StoreEntity({
    required this.sellerId,
    required this.storeId,
    required this.storeTypes,
    required this.name,
    required this.location,
    required this.image,
    required this.description,
    required this.categories,
    required this.storeLocation,
    required this.status,
    this.phone,
  });
}