import 'package:firebase_auth/firebase_auth.dart';

import '../../Domain/entites/tager_entity.dart';

class TagerModel extends TagerEntity {
  TagerModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.phone,
    required super.profileImageUrl,
    required super.accountType,
  });

  factory TagerModel.fromFirebaseUser(User user) {
    return TagerModel(
      uid: user.uid,
      email: user.email ?? '',
      name: '',
      phone: '',
      profileImageUrl: '',
      accountType: [''],
    );
  }

  factory TagerModel.fromMap(Map<String, dynamic> map) {
    return TagerModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      accountType:
          (map['accountType'] as List<dynamic>?)?.cast<String>() ?? [''],
    );
  }
}
