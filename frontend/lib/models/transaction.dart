import '../core/json_utils.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.subtotal = 0,
    this.ppnAmount = 0,
    this.taxDeduction = 0,
    this.proofUrl,
    this.paidAt,
    this.note,
    this.bookingDate,
    this.startTime,
    this.customerName,
    this.barberName,
    this.bookingStatus,
  });

  final int id;
  final int bookingId;
  final double amount;
  final double subtotal;
  final double ppnAmount;
  final double taxDeduction;
  final String paymentMethod;
  final String paymentStatus;
  final String? proofUrl;
  final String? paidAt;
  final String? note;
  final String? bookingDate;
  final String? startTime;
  final String? customerName;
  final String? barberName;
  final String? bookingStatus;

  bool get isWaiting => paymentStatus == 'waiting';
  bool get isPaid => paymentStatus == 'paid';
  bool get isRejected => paymentStatus == 'rejected';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: asInt(json['id']),
      bookingId: asInt(json['booking_id']),
      amount: asDouble(json['amount']),
      subtotal: asDouble(json['subtotal']),
      ppnAmount: asDouble(json['ppn_amount']),
      taxDeduction: asDouble(json['tax_deduction']),
      paymentMethod: asString(json['payment_method'], fallback: 'transfer'),
      paymentStatus: asString(json['payment_status'], fallback: 'waiting'),
      proofUrl: asStringOrNull(json['proof_url']),
      paidAt: asStringOrNull(json['paid_at']),
      note: asStringOrNull(json['note']),
      bookingDate: asStringOrNull(json['booking_date']),
      startTime: asStringOrNull(json['start_time']),
      customerName: asStringOrNull(json['customer_name']),
      barberName: asStringOrNull(json['barber_name']),
      bookingStatus: asStringOrNull(json['booking_status']),
    );
  }
}
