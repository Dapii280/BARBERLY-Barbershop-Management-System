import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  UserProvider(this._repository);

  final UserRepository _repository;

  List<User> _items = const [];
  bool _loading = false;
  String? _error;

  List<User> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load({bool force = false}) async {
    if (_loading && !force) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.fetchUsers();
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> updateUser({
    required int id,
    String? role,
    bool? isActive,
  }) async {
    try {
      final updated = await _repository.updateUser(
        id: id,
        role: role,
        isActive: isActive,
      );

      _items = _items.map((item) => item.id == updated.id ? updated : item).toList();
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }
}
