import '../core/json_utils.dart';
import 'booking.dart';

class TopService {
  const TopService({
    required this.serviceId,
    required this.name,
    required this.totalBooked,
    required this.revenue,
  });

  final int serviceId;
  final String name;
  final int totalBooked;
  final double revenue;

  factory TopService.fromJson(Map<String, dynamic> json) {
    return TopService(
      serviceId: asInt(json['service_id']),
      name: asString(json['name']),
      totalBooked: asInt(json['total_booked']),
      revenue: asDouble(json['revenue']),
    );
  }
}

class StatusCounts {
  const StatusCounts({
    this.pending = 0,
    this.confirmed = 0,
    this.completed = 0,
    this.cancelled = 0,
  });

  final int pending;
  final int confirmed;
  final int completed;
  final int cancelled;

  factory StatusCounts.fromJson(Map<String, dynamic> json) {
    return StatusCounts(
      pending: asInt(json['pending']),
      confirmed: asInt(json['confirmed']),
      completed: asInt(json['completed']),
      cancelled: asInt(json['cancelled']),
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    this.todayBookings = 0,
    this.totalBookings = 0,
    this.totalRevenue = 0,
    this.todayRevenue = 0,
    this.pendingTransactions = 0,
    this.totalCustomers = 0,
    this.totalBarbers = 0,
    this.statusCounts = const StatusCounts(),
    this.topServices = const [],
    this.recentBookings = const [],
  });

  final int todayBookings;
  final int totalBookings;
  final double totalRevenue;
  final double todayRevenue;
  final int pendingTransactions;
  final int totalCustomers;
  final int totalBarbers;
  final StatusCounts statusCounts;
  final List<TopService> topServices;
  final List<Booking> recentBookings;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final rawTopServices = asList(json['top_services']);
    final rawRecentBookings = asList(json['recent_bookings']);

    return DashboardSummary(
      todayBookings: asInt(json['today_bookings']),
      totalBookings: asInt(json['total_bookings']),
      totalRevenue: asDouble(json['total_revenue']),
      todayRevenue: asDouble(json['today_revenue']),
      pendingTransactions: asInt(json['pending_transactions']),
      totalCustomers: asInt(json['total_customers']),
      totalBarbers: asInt(json['total_barbers']),
      statusCounts: StatusCounts.fromJson(asMap(json['status_counts'])),
      topServices: rawTopServices
          .whereType<Map>()
          .map((item) => TopService.fromJson(item.cast<String, dynamic>()))
          .toList(),
      recentBookings: rawRecentBookings
          .whereType<Map>()
          .map((item) => Booking.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}
