import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/service.dart';

class ServiceRepository {
  Future<List<Service>> fetchServices({bool all = false}) async {
    final data = await ApiClient.instance.get(
      '/services',
      query: all ? {'all': 1} : null,
    );

    return asList(data)
        .whereType<Map>()
        .map((item) => Service.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Service> save({
    Service? service,
    required Map<String, String> fields,
    XFile? image,
  }) async {
    final form = FormData();
    fields.forEach((key, value) {
      form.fields.add(MapEntry(key, value));
    });

    if (image != null) {
      form.files.add(
        MapEntry('image', await ApiClient.instance.multipartFromXFile(image)),
      );
    }

    final data = service == null
        ? await ApiClient.instance.postForm('/services', form)
        : await ApiClient.instance.putForm('/services/${service.id}', form);

    return Service.fromJson(asMap(data));
  }

  Future<void> deleteService(int id) async {
    await ApiClient.instance.delete('/services/$id');
  }
}
