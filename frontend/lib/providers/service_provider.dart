import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../models/service.dart';
import '../repositories/service_repository.dart';

class ServiceProvider extends ChangeNotifier {
  ServiceProvider(this._repository);

  final ServiceRepository _repository;

  List<Service> _items = const [];
  bool _loading = false;
  bool _loaded = false;
  bool _lastAll = false;
  String? _error;

  List<Service> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load({bool all = false, bool force = false}) async {
    if (_loading) return;
    if (_loaded && !force && _lastAll == all) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.fetchServices(all: all);
      _loaded = true;
      _lastAll = all;
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> save({
    Service? service,
    required Map<String, String> fields,
    XFile? image,
  }) async {
    try {
      final saved = await _repository.save(
        service: service,
        fields: fields,
        image: image,
      );

      if (service == null) {
        _items = [..._items, saved];
      } else {
        _items = _items.map((item) => item.id == saved.id ? saved : item).toList();
      }

      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> remove(int id) async {
    try {
      await _repository.deleteService(id);
      _items = _items.where((item) => item.id != id).toList();
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }
}
