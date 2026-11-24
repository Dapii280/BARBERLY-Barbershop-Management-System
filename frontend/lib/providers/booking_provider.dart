import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../models/booking.dart';
import '../models/transaction.dart';
import '../repositories/booking_repository.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider(this._repository);

  final BookingRepository _repository;

  List<Booking> _items = const [];
  bool _loading = false;
  String? _error;
  String? _filterDate;
  int? _filterBarberId;
  String? _filterStatus;

  List<Booking> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load({
    String? date,
    int? barberId,
    String? status,
    bool force = false,
  }) async {
    if (_loading && !force) return;

    _filterDate = date;
    _filterBarberId = barberId;
    _filterStatus = status;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.fetchBookings(
        date: date,
        barberId: barberId,
        status: status,
      );
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reload() => load(
        date: _filterDate,
        barberId: _filterBarberId,
        status: _filterStatus,
        force: true,
      );

  Future<Booking?> create({
    required int barberId,
    required String bookingDate,
    required String startTime,
    required List<int> serviceIds,
    String? notes,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final booking = await _repository.createBooking(
        barberId: barberId,
        bookingDate: bookingDate,
        startTime: startTime,
        serviceIds: serviceIds,
        notes: notes,
      );

      _items = [booking, ..._items];
      notifyListeners();
      return booking;
    } on ApiException catch (error) {
      _error = error.message;
      notifyListeners();
      return null;
    }
  }

  Future<String?> cancel(int id) async {
    try {
      final updated = await _repository.cancelBooking(id);
      _replace(updated);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> updateStatus(int id, String status) async {
    try {
      final updated = await _repository.updateStatus(id, status);
      _replace(updated);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> pay({
    required int bookingId,
    required String paymentMethod,
    required XFile proof,
  }) async {
    try {
      final transaction = await _repository.pay(
        bookingId: bookingId,
        paymentMethod: paymentMethod,
        proof: proof,
      );
      _replaceTransaction(bookingId, transaction);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> payCash(int bookingId) async {
    try {
      final transaction = await _repository.payCash(bookingId);
      final matches = _items.where((item) => item.id == bookingId);
      final booking = matches.isEmpty ? null : matches.first;

      if (booking != null) {
        _replace(
          booking.copyWith(
            transaction: transaction,
            status: booking.isPending ? 'confirmed' : booking.status,
          ),
        );
      }
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  void _replace(Booking booking) {
    _items = _items.map((item) => item.id == booking.id ? booking : item).toList();
    notifyListeners();
  }

  void _replaceTransaction(int bookingId, TransactionModel transaction) {
    _items = _items
        .map(
          (item) => item.id == bookingId
              ? item.copyWith(transaction: transaction)
              : item,
        )
        .toList();
    notifyListeners();
  }
}
