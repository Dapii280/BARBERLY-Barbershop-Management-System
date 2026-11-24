import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._repository);

  final DashboardRepository _repository;

  DashboardSummary? _summary;
  bool _loading = false;
  String? _error;

  DashboardSummary? get summary => _summary;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load({bool force = false}) async {
    if (_loading && !force) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _summary = await _repository.fetchSummary();
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
