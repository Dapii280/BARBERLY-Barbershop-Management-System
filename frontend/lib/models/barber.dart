import '../core/json_utils.dart';

class Barber {
  const Barber({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.workStart,
    required this.workEnd,
    this.phone,
    this.specialty,
    this.bio,
    this.photoUrl,
    this.isActive = true,
  });

  final int id;
  final int userId;
  final String name;
  final String email;
  final String workStart;
  final String workEnd;
  final String? phone;
  final String? specialty;
  final String? bio;
  final String? photoUrl;
  final bool isActive;

  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  factory Barber.fromJson(Map<String, dynamic> json) {
    return Barber(
      id: asInt(json['id']),
      userId: asInt(json['user_id']),
      name: asString(json['name']),
      email: asString(json['email']),
      workStart: asString(json['work_start'], fallback: '09:00:00'),
      workEnd: asString(json['work_end'], fallback: '21:00:00'),
      phone: asStringOrNull(json['phone']),
      specialty: asStringOrNull(json['specialty']),
      bio: asStringOrNull(json['bio']),
      photoUrl: asStringOrNull(json['photo_url']),
      isActive: asBool(json['is_active'], fallback: true),
    );
  }
}
