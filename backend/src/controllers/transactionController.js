const pool = require('../config/db');
const { success } = require('../utils/response');
const { ApiError, asyncHandler } = require('../utils/asyncHandler');
const { uploadImage, deleteImage } = require('../services/cloudinaryService');

const TRANSACTION_SELECT = `
  SELECT t.id, t.booking_id, t.subtotal, t.ppn_amount, t.tax_deduction, t.amount,
         t.payment_method, t.payment_status, t.proof_url, t.proof_public_id, t.paid_at, t.note,
         b.booking_date, b.start_time, b.end_time, b.status AS booking_status,
         b.customer_id, b.barber_id,
         c.name AS customer_name, u.name AS barber_name
  FROM transactions t
  JOIN bookings b ON b.id = t.booking_id
  JOIN users c ON c.id = b.customer_id
  JOIN barbers br ON br.id = b.barber_id
  JOIN users u ON u.id = br.user_id
`;

const findTransactionDetail = async (id) => {
  const [rows] = await pool.query(`${TRANSACTION_SELECT} WHERE t.id = ?`, [id]);
  return rows[0] || null;
};

const createPayment = asyncHandler(async (req, res) => {
  const bookingId = Number(req.params.id);
  const { payment_method } = req.validatedBody;

  const [bookingRows] = await pool.query(
    `SELECT id, customer_id, status, subtotal, ppn_amount, tax_deduction, total_price
     FROM bookings WHERE id = ?`,
    [bookingId]
  );
  if (bookingRows.length === 0) throw new ApiError(404, 'Booking tidak ditemukan');

  const booking = bookingRows[0];
  if (booking.customer_id !== req.user.id) {
    throw new ApiError(403, 'Anda tidak berhak membayar booking ini');
  }
  if (booking.status === 'cancelled') throw new ApiError(400, 'Booking sudah dibatalkan');
  if (booking.status === 'completed') throw new ApiError(400, 'Booking sudah selesai');

  if (!req.file) throw new ApiError(400, 'Bukti pembayaran wajib diunggah');

  const [existingRows] = await pool.query(
    'SELECT id, payment_status, proof_public_id FROM transactions WHERE booking_id = ?',
    [bookingId]
  );
  const existing = existingRows[0];
  if (existing && existing.payment_status === 'paid') {
    throw new ApiError(409, 'Pembayaran booking ini sudah lunas');
  }

  const uploaded = await uploadImage(req.file.buffer, 'payments', req.file.mimetype);
  let transactionId;

  if (existing) {
    await pool.query(
      `UPDATE transactions
       SET subtotal = ?, ppn_amount = ?, tax_deduction = ?, amount = ?, payment_method = ?,
           payment_status = 'waiting', proof_url = ?, proof_public_id = ?, paid_at = NULL, note = NULL
       WHERE id = ?`,
      [
        booking.subtotal,
        booking.ppn_amount,
        booking.tax_deduction,
        booking.total_price,
        payment_method,
        uploaded.url,
        uploaded.publicId,
        existing.id,
      ]
    );
    transactionId = existing.id;

    if (existing.proof_public_id) await deleteImage(existing.proof_public_id);
  } else {
    const [result] = await pool.query(
      `INSERT INTO transactions
        (booking_id, subtotal, ppn_amount, tax_deduction, amount, payment_method, payment_status, proof_url, proof_public_id)
       VALUES (?, ?, ?, ?, ?, ?, 'waiting', ?, ?)`,
      [
        bookingId,
        booking.subtotal,
        booking.ppn_amount,
        booking.tax_deduction,
        booking.total_price,
        payment_method,
        uploaded.url,
        uploaded.publicId,
      ]
    );
    transactionId = result.insertId;
  }

  return success(
    res,
    'Bukti pembayaran berhasil dikirim, menunggu verifikasi admin',
    await findTransactionDetail(transactionId),
    201
  );
});

const createCashPayment = asyncHandler(async (req, res) => {
  const bookingId = Number(req.params.id);

  const [bookingRows] = await pool.query(
    `SELECT id, status, subtotal, ppn_amount, tax_deduction, total_price
     FROM bookings WHERE id = ?`,
    [bookingId]
  );
  if (bookingRows.length === 0) throw new ApiError(404, 'Booking tidak ditemukan');

  const booking = bookingRows[0];
  if (booking.status === 'cancelled') throw new ApiError(400, 'Booking sudah dibatalkan');

  const [existingRows] = await pool.query(
    'SELECT id, payment_status FROM transactions WHERE booking_id = ?',
    [bookingId]
  );

  let transactionId;
  if (existingRows.length > 0) {
    if (existingRows[0].payment_status === 'paid') {
      throw new ApiError(409, 'Booking ini sudah memiliki pembayaran lunas');
    }

    await pool.query(
      `UPDATE transactions
       SET subtotal = ?, ppn_amount = ?, tax_deduction = ?, amount = ?, payment_method = 'cash',
           payment_status = 'paid', paid_at = NOW(), note = NULL
       WHERE id = ?`,
      [
        booking.subtotal,
        booking.ppn_amount,
        booking.tax_deduction,
        booking.total_price,
        existingRows[0].id,
      ]
    );
    transactionId = existingRows[0].id;
  } else {
    const [result] = await pool.query(
      `INSERT INTO transactions
        (booking_id, subtotal, ppn_amount, tax_deduction, amount, payment_method, payment_status, paid_at)
       VALUES (?, ?, ?, ?, ?, 'cash', 'paid', NOW())`,
      [bookingId, booking.subtotal, booking.ppn_amount, booking.tax_deduction, booking.total_price]
    );
    transactionId = result.insertId;
  }

  await pool.query("UPDATE bookings SET status = 'confirmed' WHERE id = ? AND status = 'pending'", [
    bookingId,
  ]);

  return success(
    res,
    'Pembayaran tunai berhasil dicatat',
    await findTransactionDetail(transactionId),
    201
  );
});

const listTransactions = asyncHandler(async (req, res) => {
  const { payment_status } = req.validatedQuery || {};
  const filters = [];
  const values = [];

  if (req.user.role === 'customer') {
    filters.push('b.customer_id = ?');
    values.push(req.user.id);
  }

  if (payment_status) {
    filters.push('t.payment_status = ?');
    values.push(payment_status);
  }

  const where = filters.length > 0 ? `WHERE ${filters.join(' AND ')}` : '';
  const [rows] = await pool.query(
    `${TRANSACTION_SELECT} ${where}
     ORDER BY FIELD(t.payment_status, 'waiting', 'rejected', 'paid'), t.id DESC`,
    values
  );

  return success(res, 'Daftar transaksi berhasil diambil', rows);
});

const verifyTransaction = asyncHandler(async (req, res) => {
  const transactionId = Number(req.params.id);
  const { payment_status, note } = req.validatedBody;

  const [rows] = await pool.query(
    `SELECT t.id, t.booking_id, t.payment_status, b.status AS booking_status
     FROM transactions t JOIN bookings b ON b.id = t.booking_id
     WHERE t.id = ?`,
    [transactionId]
  );
  if (rows.length === 0) throw new ApiError(404, 'Transaksi tidak ditemukan');

  const transaction = rows[0];
  if (transaction.payment_status === 'paid') {
    throw new ApiError(409, 'Transaksi ini sudah diverifikasi lunas');
  }
  if (transaction.booking_status === 'cancelled') {
    throw new ApiError(400, 'Booking sudah dibatalkan, transaksi tidak dapat diverifikasi');
  }
  if (payment_status === 'rejected' && !note) {
    throw new ApiError(400, 'Catatan alasan penolakan wajib diisi');
  }

  await pool.query(
    `UPDATE transactions
     SET payment_status = ?, note = ?, paid_at = ${payment_status === 'paid' ? 'NOW()' : 'NULL'}
     WHERE id = ?`,
    [payment_status, note || null, transactionId]
  );

  if (payment_status === 'paid') {
    await pool.query(
      "UPDATE bookings SET status = 'confirmed' WHERE id = ? AND status = 'pending'",
      [transaction.booking_id]
    );
  }

  return success(
    res,
    payment_status === 'paid' ? 'Transaksi berhasil disetujui' : 'Transaksi ditolak',
    await findTransactionDetail(transactionId)
  );
});

module.exports = { createPayment, createCashPayment, listTransactions, verifyTransaction };
