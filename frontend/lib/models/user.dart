import '../core/json_utils.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.photoUrl,
    this.isActive = true,
    this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? photoUrl;
  final bool isActive;
  final String? createdAt;

  bool get isAdmin => role == 'admin';
  bool get isBarber => role == 'barber';
  bool get isCustomer => role == 'customer';

  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: asInt(json['id']),
      name: asString(json['name']),
      email: asString(json['email']),
      role: asString(json['role'], fallback: 'customer'),
      phone: asStringOrNull(json['phone']),
      photoUrl: asStringOrNull(json['photo_url']),
      isActive: asBool(json['is_active'], fallback: true),
      createdAt: asStringOrNull(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'photo_url': photoUrl,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };
}
