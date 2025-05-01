import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserEntity {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String profileImageUrl;
  final List<String> accountType;
  final String location;
  final bool emailVerified;
  LatLng? userLocation;

  UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.profileImageUrl,
    required this.accountType,
    required this.location,
    this.userLocation,
    this.emailVerified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'accountType': accountType,
      'location': location,
      'emailVerified': emailVerified,
      'userLocation': userLocation != null ? {
        'latitude': userLocation!.latitude,
        'longitude': userLocation!.longitude,
      } : null,
    };
  }

  UserEntity copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? profileImageUrl,
    List<String>? accountType,
    String? location,
    bool? emailVerified,
    LatLng? userLocation,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      accountType: accountType ?? this.accountType,
      location: location ?? this.location,
      emailVerified: emailVerified ?? this.emailVerified,
      userLocation: userLocation ?? this.userLocation,
    );
  }
}
