import '../core/json_utils.dart';
import 'transaction.dart';

class BookingItem {
  const BookingItem({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.imageUrl,
  });

  final int id;
  final int serviceId;
  final String name;
  final double price;
  final int durationMinutes;
  final String? imageUrl;

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    return BookingItem(
      id: asInt(json['id']),
      serviceId: asInt(json['service_id']),
      name: asString(json['name']),
      price: asDouble(json['price']),
      durationMinutes: asInt(json['duration_minutes']),
      imageUrl: asStringOrNull(json['image_url']),
    );
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.barberId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.subtotal,
    required this.ppnAmount,
    required this.taxDeduction,
    required this.totalPrice,
    this.customerName = '',
    this.customerPhone,
    this.barberName = '',
    this.notes,
    this.createdAt,
    this.items = const [],
    this.transaction,
  });

  final int id;
  final int customerId;
  final int barberId;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final double subtotal;
  final double ppnAmount;
  final double taxDeduction;
  final double totalPrice;
  final String customerName;
  final String? customerPhone;
  final String barberName;
  final String? notes;
  final String? createdAt;
  final List<BookingItem> items;
  final TransactionModel? transaction;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get canCancel => status == 'pending' || status == 'confirmed';

  bool get canPay {
    if (isCancelled || isCompleted) return false;
    final payment = transaction;
    return payment == null || payment.isRejected;
  }

  bool get hasWaitingPayment => transaction?.isWaiting ?? false;
  bool get isPaid => transaction?.isPaid ?? false;

  int get totalDuration =>
      items.fold(0, (total, item) => total + item.durationMinutes);

  String get serviceNames => items.map((item) => item.name).join(', ');

  Booking copyWith({
    String? status,
    TransactionModel? transaction,
  }) {
    return Booking(
      id: id,
      customerId: customerId,
      barberId: barberId,
      bookingDate: bookingDate,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      subtotal: subtotal,
      ppnAmount: ppnAmount,
      taxDeduction: taxDeduction,
      totalPrice: totalPrice,
      customerName: customerName,
      customerPhone: customerPhone,
      barberName: barberName,
      notes: notes,
      createdAt: createdAt,
      items: items,
      transaction: transaction ?? this.transaction,
    );
  }


  factory Booking.fromJson(Map<String, dynamic> json) {
    final rawItems = asList(json['items']);
    final rawTransaction = json['transaction'];

    return Booking(
      id: asInt(json['id']),
      customerId: asInt(json['customer_id']),
      barberId: asInt(json['barber_id']),
      bookingDate: asString(json['booking_date']),
      startTime: asString(json['start_time']),
      endTime: asString(json['end_time']),
      status: asString(json['status'], fallback: 'pending'),
      subtotal: asDouble(json['subtotal']),
      ppnAmount: asDouble(json['ppn_amount']),
      taxDeduction: asDouble(json['tax_deduction']),
      totalPrice: asDouble(json['total_price']),
      customerName: asString(json['customer_name']),
      customerPhone: asStringOrNull(json['customer_phone']),
      barberName: asString(json['barber_name']),
      notes: asStringOrNull(json['notes']),
      createdAt: asStringOrNull(json['created_at']),
      items: rawItems
          .whereType<Map>()
          .map((item) => BookingItem.fromJson(item.cast<String, dynamic>()))
          .toList(),
      transaction: rawTransaction is Map
          ? TransactionModel.fromJson(rawTransaction.cast<String, dynamic>())
          : null,
    );
  }
}
