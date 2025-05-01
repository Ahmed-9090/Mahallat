class TagerEntity {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final List<String> accountType;
  final String profileImageUrl;

  TagerEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.accountType,
    required this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'accountTypes': accountType,
      'profileImageUrl': profileImageUrl,
    };
  }
}
