import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../models/barber.dart';
import '../repositories/barber_repository.dart';

class BarberProvider extends ChangeNotifier {
  BarberProvider(this._repository);

  final BarberRepository _repository;

  List<Barber> _items = const [];
  List<String> _slots = const [];
  bool _loading = false;
  bool _slotsLoading = false;
  bool _loaded = false;
  bool _lastAll = false;
  String? _error;
  String? _slotsError;
  int _slotsRequestId = 0;

  List<Barber> get items => _items;
  List<String> get slots => _slots;
  bool get loading => _loading;
  bool get slotsLoading => _slotsLoading;
  String? get error => _error;
  String? get slotsError => _slotsError;

  Future<void> load({bool all = false, bool force = false}) async {
    if (_loading) return;
    if (_loaded && !force && _lastAll == all) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.fetchBarbers(all: all);
      _loaded = true;
      _lastAll = all;
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> loadAvailability({
    required int barberId,
    required String date,
    required int duration,
  }) async {
    final requestId = ++_slotsRequestId;

    _slotsLoading = true;
    _slotsError = null;
    _slots = const [];
    notifyListeners();

    try {
      final slots = await _repository.fetchAvailability(
        barberId: barberId,
        date: date,
        duration: duration,
      );

      if (requestId == _slotsRequestId) {
        _slots = slots;
      }
      return null;
    } on ApiException catch (error) {
      if (requestId == _slotsRequestId) {
        _slotsError = error.message;
      }
      return error.message;
    } finally {
      if (requestId == _slotsRequestId) {
        _slotsLoading = false;
        notifyListeners();
      }
    }
  }

  void clearSlots() {
    _slotsRequestId++;
    _slots = const [];
    _slotsError = null;
    _slotsLoading = false;
    notifyListeners();
  }

  Future<String?> save({
    Barber? barber,
    required Map<String, String> fields,
    XFile? photo,
  }) async {
    try {
      final saved = await _repository.save(
        barber: barber,
        fields: fields,
        photo: photo,
      );

      if (barber == null) {
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
      await _repository.deleteBarber(id);
      _items = _items.where((item) => item.id != id).toList();
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }
}
