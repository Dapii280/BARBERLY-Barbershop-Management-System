import '../core/json_utils.dart';

class Service {
  const Service({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  final int id;
  final String name;
  final double price;
  final int durationMinutes;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: asInt(json['id']),
      name: asString(json['name']),
      price: asDouble(json['price']),
      durationMinutes: asInt(json['duration_minutes']),
      description: asStringOrNull(json['description']),
      imageUrl: asStringOrNull(json['image_url']),
      isActive: asBool(json['is_active'], fallback: true),
    );
  }
}
