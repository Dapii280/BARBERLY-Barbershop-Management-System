import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/booking.dart';
import '../models/transaction.dart';

class BookingRepository {
  Future<List<Booking>> fetchBookings({
    String? date,
    int? barberId,
    String? status,
  }) async {
    final query = <String, dynamic>{};
    if (date != null && date.isNotEmpty) query['date'] = date;
    if (barberId != null) query['barber_id'] = barberId;
    if (status != null && status.isNotEmpty) query['status'] = status;

    final data = await ApiClient.instance.get(
      '/bookings',
      query: query.isEmpty ? null : query,
    );

    return asList(data)
        .whereType<Map>()
        .map((item) => Booking.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Booking> getBooking(int id) async {
    final data = await ApiClient.instance.get('/bookings/$id');
    return Booking.fromJson(asMap(data));
  }

  Future<Booking> createBooking({
    required int barberId,
    required String bookingDate,
    required String startTime,
    required List<int> serviceIds,
    String? notes,
  }) async {
    final data = await ApiClient.instance.post(
      '/bookings',
      body: {
        'barber_id': barberId,
        'booking_date': bookingDate,
        'start_time': startTime,
        'service_ids': serviceIds,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    return Booking.fromJson(asMap(data));
  }

  Future<Booking> cancelBooking(int id) async {
    final data = await ApiClient.instance.patch('/bookings/$id/cancel');
    return Booking.fromJson(asMap(data));
  }

  Future<Booking> updateStatus(int id, String status) async {
    final data = await ApiClient.instance.patch(
      '/bookings/$id/status',
      body: {'status': status},
    );

    return Booking.fromJson(asMap(data));
  }

  Future<TransactionModel> pay({
    required int bookingId,
    required String paymentMethod,
    required XFile proof,
  }) async {
    final form = FormData();
    form.fields.add(MapEntry('payment_method', paymentMethod));
    form.files.add(
      MapEntry('proof', await ApiClient.instance.multipartFromXFile(proof)),
    );

    final data = await ApiClient.instance.postForm(
      '/bookings/$bookingId/payment',
      form,
    );

    return TransactionModel.fromJson(asMap(data));
  }

  Future<TransactionModel> payCash(int bookingId) async {
    final data = await ApiClient.instance.post('/bookings/$bookingId/cash');
    return TransactionModel.fromJson(asMap(data));
  }
}
