import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider(this._repository);

  final TransactionRepository _repository;

  List<TransactionModel> _items = const [];
  bool _loading = false;
  String? _error;
  String? _paymentStatus;

  List<TransactionModel> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load({String? paymentStatus, bool force = false}) async {
    if (_loading && !force) return;

    _paymentStatus = paymentStatus;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.fetchTransactions(paymentStatus: paymentStatus);
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> verify({
    required int id,
    required String paymentStatus,
    String? note,
  }) async {
    try {
      final updated = await _repository.verify(
        id: id,
        paymentStatus: paymentStatus,
        note: note,
      );

      if (_paymentStatus != null && updated.paymentStatus != _paymentStatus) {
        _items = _items.where((item) => item.id != updated.id).toList();
      } else {
        _items = _items
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      }

      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }
}
