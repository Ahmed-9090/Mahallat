import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../Domain/entites/user_entity.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final List<String> accountType;
  final String profileImageUrl;
  final String location;
  LatLng? userLocation;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.accountType,
    required this.profileImageUrl,
    required this.location,
    this.userLocation,
  });

  // Convert Firebase User to Model
  factory UserModel.fromFirebaseUser(User user, Map<String, dynamic> data) {
    LatLng? userLocation;
    if (data['userLocation'] != null) {
      if (data['userLocation'] is Map) {
        final locationMap = data['userLocation'] as Map<String, dynamic>;
        userLocation = LatLng(
          locationMap['latitude'] as double,
          locationMap['longitude'] as double,
        );
      } else if (data['userLocation'] is LatLng) {
        userLocation = data['userLocation'] as LatLng;
      }
    }

    return UserModel(
      uid: user.uid,
      name: data['name'] ?? '',
      email: user.email ?? data['email'] ?? '',
      phone: data['phone'] ?? '',
      accountType: (data['accountType'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['user'],
      profileImageUrl: data['profileImageUrl'] ?? '',
      location: data['location'] ?? '',
      userLocation: userLocation,
    );
  }

  // Convert Entity to Model
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      accountType: entity.accountType,
      profileImageUrl: entity.profileImageUrl,
      location: entity.location,
      userLocation: entity.userLocation,
    );
  }

  // Convert Map to Model
  factory UserModel.fromMap(Map<String, dynamic> map) {
    LatLng? userLocation;
    if (map['userLocation'] != null) {
      if (map['userLocation'] is Map) {
        final locationMap = map['userLocation'] as Map<String, dynamic>;
        userLocation = LatLng(
          locationMap['latitude'] as double,
          locationMap['longitude'] as double,
        );
      } else if (map['userLocation'] is LatLng) {
        userLocation = map['userLocation'] as LatLng;
      }
    }

    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      accountType: (map['accountType'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['user'],
      profileImageUrl: map['profileImageUrl'] ?? '',
      location: map['location'] ?? '',
      userLocation: userLocation,
    );
  }

  // Convert Model to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'accountType': accountType,
      'profileImageUrl': profileImageUrl,
      'location': location,
      'userLocation': userLocation != null ? {
        'latitude': userLocation!.latitude,
        'longitude': userLocation!.longitude,
      } : null,
    };
  }

  // Check if user is seller
  bool get isSeller {
    if (accountType is String) {
      return accountType != 'user';
    } else if (accountType is List) {
      return (accountType as List).isNotEmpty;
    }
    return false;
  }

  // Get seller categories (if any)
  List<String> get sellerCategories {
    if (accountType is List) {
      return List<String>.from(accountType);
    }
    return [];
  }

  // Convert to Entity
  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      profileImageUrl: profileImageUrl,
      accountType: accountType,
      location: location,
      userLocation: userLocation
    );
  }
}