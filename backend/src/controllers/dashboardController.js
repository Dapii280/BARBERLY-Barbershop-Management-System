const pool = require('../config/db');
const { success } = require('../utils/response');
const { asyncHandler } = require('../utils/asyncHandler');
const { todayString } = require('../utils/time');

const getSummary = asyncHandler(async (req, res) => {
  const today = todayString();

  const [
    todayBookings,
    totalBookings,
    revenue,
    todayRevenue,
    pendingTransactions,
    totalCustomers,
    totalBarbers,
    statusRows,
    topServices,
    recentBookings,
  ] = await Promise.all([
    pool.query('SELECT COUNT(*) AS total FROM bookings WHERE booking_date = ? AND status <> ?', [
      today,
      'cancelled',
    ]),
    pool.query('SELECT COUNT(*) AS total FROM bookings'),
    pool.query("SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE payment_status = 'paid'"),
    pool.query(
      `SELECT COALESCE(SUM(t.amount), 0) AS total
       FROM transactions t JOIN bookings b ON b.id = t.booking_id
       WHERE t.payment_status = 'paid' AND b.booking_date = ?`,
      [today]
    ),
    pool.query("SELECT COUNT(*) AS total FROM transactions WHERE payment_status = 'waiting'"),
    pool.query("SELECT COUNT(*) AS total FROM users WHERE role = 'customer'"),
    pool.query('SELECT COUNT(*) AS total FROM barbers WHERE is_active = 1'),
    pool.query('SELECT status, COUNT(*) AS total FROM bookings GROUP BY status'),
    pool.query(
      `SELECT s.id AS service_id, s.name, COUNT(bi.id) AS total_booked, SUM(bi.price) AS revenue
       FROM booking_items bi
       JOIN services s ON s.id = bi.service_id
       JOIN bookings b ON b.id = bi.booking_id AND b.status <> 'cancelled'
       GROUP BY s.id, s.name
       ORDER BY total_booked DESC, revenue DESC
       LIMIT 5`
    ),
    pool.query(
      `SELECT b.id, b.booking_date, b.start_time, b.status, b.total_price,
              c.name AS customer_name, u.name AS barber_name
       FROM bookings b
       JOIN users c ON c.id = b.customer_id
       JOIN barbers br ON br.id = b.barber_id
       JOIN users u ON u.id = br.user_id
       ORDER BY b.id DESC
       LIMIT 5`
    ),
  ]);

  const statusCounts = { pending: 0, confirmed: 0, completed: 0, cancelled: 0 };
  statusRows[0].forEach((row) => {
    statusCounts[row.status] = Number(row.total);
  });

  return success(res, 'Ringkasan dashboard berhasil diambil', {
    today_bookings: Number(todayBookings[0][0].total),
    total_bookings: Number(totalBookings[0][0].total),
    total_revenue: Number(revenue[0][0].total),
    today_revenue: Number(todayRevenue[0][0].total),
    pending_transactions: Number(pendingTransactions[0][0].total),
    total_customers: Number(totalCustomers[0][0].total),
    total_barbers: Number(totalBarbers[0][0].total),
    status_counts: statusCounts,
    top_services: topServices[0],
    recent_bookings: recentBookings[0],
  });
});

module.exports = { getSummary };
