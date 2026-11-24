const pool = require('../config/db');
const { success } = require('../utils/response');
const { ApiError, asyncHandler } = require('../utils/asyncHandler');
const { calculateBill } = require('../utils/calculateBill');
const { addMinutes, normalizeTime, toMinutes, todayString, isOverlap } = require('../utils/time');

const BOOKING_SELECT = `
  SELECT b.id, b.customer_id, b.barber_id, b.booking_date, b.start_time, b.end_time, b.status,
         b.subtotal, b.ppn_amount, b.tax_deduction, b.total_price, b.notes, b.created_at,
         c.name AS customer_name, c.phone AS customer_phone, c.email AS customer_email,
         u.name AS barber_name, br.specialty AS barber_specialty
  FROM bookings b
  JOIN users c ON c.id = b.customer_id
  JOIN barbers br ON br.id = b.barber_id
  JOIN users u ON u.id = br.user_id
`;

const getBarberIdByUser = async (userId) => {
  const [rows] = await pool.query('SELECT id FROM barbers WHERE user_id = ?', [userId]);
  return rows[0] ? rows[0].id : null;
};

// Melengkapi booking dengan item layanan (snapshot harga) dan transaksi
const attachRelations = async (bookings) => {
  if (bookings.length === 0) return bookings;

  const ids = bookings.map((booking) => booking.id);
  const placeholders = ids.map(() => '?').join(', ');

  const [items] = await pool.query(
    `SELECT bi.id, bi.booking_id, bi.service_id, bi.price, s.name, s.duration_minutes, s.image_url
     FROM booking_items bi
     JOIN services s ON s.id = bi.service_id
     WHERE bi.booking_id IN (${placeholders})
     ORDER BY bi.id ASC`,
    ids
  );

  const [transactions] = await pool.query(
    `SELECT id, booking_id, subtotal, ppn_amount, tax_deduction, amount, payment_method,
            payment_status, proof_url, paid_at, note
     FROM transactions
     WHERE booking_id IN (${placeholders})`,
    ids
  );

  const itemsByBooking = new Map();
  items.forEach((item) => {
    if (!itemsByBooking.has(item.booking_id)) itemsByBooking.set(item.booking_id, []);
    itemsByBooking.get(item.booking_id).push(item);
  });

  const transactionByBooking = new Map(
    transactions.map((transaction) => [transaction.booking_id, transaction])
  );

  return bookings.map((booking) => ({
    ...booking,
    items: itemsByBooking.get(booking.id) || [],
    transaction: transactionByBooking.get(booking.id) || null,
  }));
};

const findBookingDetail = async (id) => {
  const [rows] = await pool.query(`${BOOKING_SELECT} WHERE b.id = ?`, [id]);
  if (rows.length === 0) return null;

  const [detail] = await attachRelations(rows);
  return detail;
};

const listBookings = asyncHandler(async (req, res) => {
  const { date, barber_id, status } = req.validatedQuery || {};
  const filters = [];
  const values = [];

  if (req.user.role === 'customer') {
    filters.push('b.customer_id = ?');
    values.push(req.user.id);
  } else if (req.user.role === 'barber') {
    const barberId = await getBarberIdByUser(req.user.id);
    if (!barberId) return success(res, 'Belum ada jadwal untuk akun barber ini', []);

    filters.push('b.barber_id = ?');
    values.push(barberId);
  }

  if (date) {
    filters.push('b.booking_date = ?');
    values.push(date);
  }
  if (barber_id) {
    filters.push('b.barber_id = ?');
    values.push(barber_id);
  }
  if (status) {
    filters.push('b.status = ?');
    values.push(status);
  }

  const where = filters.length > 0 ? `WHERE ${filters.join(' AND ')}` : '';
  const [rows] = await pool.query(
    `${BOOKING_SELECT} ${where} ORDER BY b.booking_date DESC, b.start_time DESC`,
    values
  );

  return success(res, 'Daftar booking berhasil diambil', await attachRelations(rows));
});

const getBooking = asyncHandler(async (req, res) => {
  const booking = await findBookingDetail(Number(req.params.id));
  if (!booking) throw new ApiError(404, 'Booking tidak ditemukan');

  if (req.user.role === 'customer' && booking.customer_id !== req.user.id) {
    throw new ApiError(403, 'Anda tidak berhak melihat booking ini');
  }

  if (req.user.role === 'barber') {
    const barberId = await getBarberIdByUser(req.user.id);
    if (barberId !== booking.barber_id) {
      throw new ApiError(403, 'Anda tidak berhak melihat booking ini');
    }
  }

  return success(res, 'Detail booking berhasil diambil', booking);
});

const createBooking = asyncHandler(async (req, res) => {
  const { barber_id, booking_date, start_time, service_ids, notes } = req.validatedBody;

  if (booking_date < todayString()) {
    throw new ApiError(400, 'Tanggal booking tidak boleh di masa lalu');
  }

  if (new Set(service_ids).size !== service_ids.length) {
    throw new ApiError(400, 'Layanan yang dipilih tidak boleh duplikat');
  }

  const servicePlaceholders = service_ids.map(() => '?').join(', ');
  const [serviceRows] = await pool.query(
    `SELECT id, name, price, duration_minutes, is_active FROM services WHERE id IN (${servicePlaceholders})`,
    service_ids
  );

  if (serviceRows.length !== service_ids.length) {
    throw new ApiError(400, 'Ada layanan yang tidak ditemukan');
  }
  if (serviceRows.some((service) => service.is_active !== 1)) {
    throw new ApiError(400, 'Ada layanan yang sedang tidak aktif');
  }

  // Jaga urutan layanan sesuai pilihan pelanggan
  const services = service_ids.map((id) => serviceRows.find((service) => service.id === id));

  const totalDuration = services.reduce((total, service) => total + service.duration_minutes, 0);
  const normalizedStart = normalizeTime(start_time);
  const normalizedEnd = addMinutes(normalizedStart, totalDuration);
  const bill = calculateBill(services.map((service) => service.price));

  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    // Lock baris barber agar dua pelanggan tidak mendapat slot yang sama
    const [barberRows] = await connection.query(
      `SELECT b.id, b.work_start, b.work_end, b.is_active, u.is_active AS user_active
       FROM barbers b JOIN users u ON u.id = b.user_id
       WHERE b.id = ? FOR UPDATE`,
      [barber_id]
    );

    const barber = barberRows[0];
    if (!barber || barber.is_active !== 1 || barber.user_active !== 1) {
      throw new ApiError(404, 'Barber tidak ditemukan atau sedang nonaktif');
    }

    if (
      toMinutes(normalizedStart) < toMinutes(barber.work_start) ||
      toMinutes(normalizedEnd) > toMinutes(barber.work_end)
    ) {
      throw new ApiError(
        400,
        `Booking harus di dalam jam kerja barber (${barber.work_start.slice(0, 5)} - ${barber.work_end.slice(0, 5)})`
      );
    }

    const [existing] = await connection.query(
      `SELECT id, start_time, end_time FROM bookings
       WHERE barber_id = ? AND booking_date = ? AND status <> 'cancelled'`,
      [barber_id, booking_date]
    );

    const hasConflict = existing.some((booking) =>
      isOverlap(normalizedStart, normalizedEnd, booking.start_time, booking.end_time)
    );
    if (hasConflict) {
      throw new ApiError(409, 'Jadwal barber pada jam tersebut sudah dipesan, pilih jam lain');
    }

    const [bookingResult] = await connection.query(
      `INSERT INTO bookings
        (customer_id, barber_id, booking_date, start_time, end_time, status, subtotal, ppn_amount, tax_deduction, total_price, notes)
       VALUES (?, ?, ?, ?, ?, 'pending', ?, ?, ?, ?, ?)`,
      [
        req.user.id,
        barber_id,
        booking_date,
        normalizedStart,
        normalizedEnd,
        bill.subtotal,
        bill.ppn_amount,
        bill.tax_deduction,
        bill.total_price,
        notes || null,
      ]
    );

    // Snapshot harga layanan: riwayat tidak berubah walau harga master diedit
    for (const service of services) {
      await connection.query(
        'INSERT INTO booking_items (booking_id, service_id, price) VALUES (?, ?, ?)',
        [bookingResult.insertId, service.id, service.price]
      );
    }

    await connection.commit();

    const booking = await findBookingDetail(bookingResult.insertId);
    return success(res, 'Booking berhasil dibuat', booking, 201);
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
});

const cancelBooking = asyncHandler(async (req, res) => {
  const bookingId = Number(req.params.id);

  const [rows] = await pool.query('SELECT id, customer_id, status FROM bookings WHERE id = ?', [
    bookingId,
  ]);
  if (rows.length === 0) throw new ApiError(404, 'Booking tidak ditemukan');

  const booking = rows[0];

  if (req.user.role === 'customer' && booking.customer_id !== req.user.id) {
    throw new ApiError(403, 'Anda tidak berhak membatalkan booking ini');
  }

  if (booking.status === 'cancelled') throw new ApiError(400, 'Booking sudah dibatalkan');
  if (booking.status === 'completed') throw new ApiError(400, 'Booking yang selesai tidak dapat dibatalkan');

  await pool.query("UPDATE bookings SET status = 'cancelled' WHERE id = ?", [bookingId]);

  return success(res, 'Booking berhasil dibatalkan', await findBookingDetail(bookingId));
});

const updateBookingStatus = asyncHandler(async (req, res) => {
  const bookingId = Number(req.params.id);
  const { status } = req.validatedBody;

  const [rows] = await pool.query('SELECT id, barber_id, status FROM bookings WHERE id = ?', [
    bookingId,
  ]);
  if (rows.length === 0) throw new ApiError(404, 'Booking tidak ditemukan');

  const booking = rows[0];

  if (req.user.role === 'barber') {
    const barberId = await getBarberIdByUser(req.user.id);
    if (barberId !== booking.barber_id) {
      throw new ApiError(403, 'Anda hanya dapat mengubah booking milik Anda');
    }
  }

  if (booking.status === 'cancelled') throw new ApiError(400, 'Booking sudah dibatalkan');
  if (booking.status === 'completed' && status === 'confirmed') {
    throw new ApiError(400, 'Booking sudah selesai');
  }

  await pool.query('UPDATE bookings SET status = ? WHERE id = ?', [status, bookingId]);

  return success(
    res,
    status === 'completed' ? 'Booking ditandai selesai' : 'Booking berhasil dikonfirmasi',
    await findBookingDetail(bookingId)
  );
});

module.exports = {
  listBookings,
  getBooking,
  createBooking,
  cancelBooking,
  updateBookingStatus,
};
