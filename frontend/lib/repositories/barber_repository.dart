import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/barber.dart';

class BarberRepository {
  Future<List<Barber>> fetchBarbers({bool all = false}) async {
    final data = await ApiClient.instance.get(
      '/barbers',
      query: all ? {'all': 1} : null,
    );

    return asList(data)
        .whereType<Map>()
        .map((item) => Barber.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Barber> getBarber(int id) async {
    final data = await ApiClient.instance.get('/barbers/$id');
    return Barber.fromJson(asMap(data));
  }

  Future<List<String>> fetchAvailability({
    required int barberId,
    required String date,
    required int duration,
  }) async {
    final data = await ApiClient.instance.get(
      '/barbers/$barberId/availability',
      query: {'date': date, 'duration': duration},
    );

    return asList(asMap(data)['slots']).map((slot) => asString(slot)).toList();
  }

  Future<Barber> save({
    Barber? barber,
    required Map<String, String> fields,
    XFile? photo,
  }) async {
    final form = FormData();
    fields.forEach((key, value) {
      form.fields.add(MapEntry(key, value));
    });

    if (photo != null) {
      form.files.add(
        MapEntry('photo', await ApiClient.instance.multipartFromXFile(photo)),
      );
    }

    final data = barber == null
        ? await ApiClient.instance.postForm('/barbers', form)
        : await ApiClient.instance.putForm('/barbers/${barber.id}', form);

    return Barber.fromJson(asMap(data));
  }

  Future<void> deleteBarber(int id) async {
    await ApiClient.instance.delete('/barbers/$id');
  }
}
