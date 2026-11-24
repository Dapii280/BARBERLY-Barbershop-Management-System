import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/user.dart';

class UserRepository {
  Future<User> updateMe({
    String? name,
    String? phone,
    String? password,
    String? currentPassword,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
      body['current_password'] = currentPassword;
    }

    final data = await ApiClient.instance.put('/users/me', body: body);
    return User.fromJson(asMap(data));
  }

  Future<User> uploadPhoto(XFile file) async {
    final form = FormData();
    form.files.add(
      MapEntry('photo', await ApiClient.instance.multipartFromXFile(file)),
    );

    final data = await ApiClient.instance.postForm('/users/me/photo', form);
    return User.fromJson(asMap(data));
  }

  Future<List<User>> fetchUsers() async {
    final data = await ApiClient.instance.get('/users');
    return asList(data)
        .whereType<Map>()
        .map((item) => User.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<User> updateUser({
    required int id,
    String? role,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (role != null) body['role'] = role;
    if (isActive != null) body['is_active'] = isActive ? 1 : 0;

    final data = await ApiClient.instance.patch('/users/$id', body: body);
    return User.fromJson(asMap(data));
  }
}
