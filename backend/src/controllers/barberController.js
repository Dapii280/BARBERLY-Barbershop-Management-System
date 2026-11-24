const bcrypt = require('bcrypt');
const pool = require('../config/db');
const { success } = require('../utils/response');
const { ApiError, asyncHandler } = require('../utils/asyncHandler');
const { uploadImage, deleteImage } = require('../services/cloudinaryService');
const {
  toMinutes,
  addMinutes,
  normalizeTime,
  todayString,
  currentTimeString,
  isOverlap,
} = require('../utils/time');

const BARBER_SELECT = `
  SELECT b.id, b.user_id, u.name, u.email, u.phone, b.specialty, b.bio,
         b.photo_url, b.photo_public_id, u.photo_public_id AS user_photo_public_id,
         b.work_start, b.work_end, b.is_active
  FROM barbers b
  JOIN users u ON u.id = b.user_id
`;

const getBarberRow = async (id) => {
  const [rows] = await pool.query(`${BARBER_SELECT} WHERE b.id = ?`, [id]);
  return rows[0] || null;
};

const listBarbers = asyncHandler(async (req, res) => {
  const showAll = String(req.query.all || '') === '1' && req.user.role === 'admin';
  const [rows] = await pool.query(
    `${BARBER_SELECT} ${showAll ? '' : 'WHERE b.is_active = 1 AND u.is_active = 1'} ORDER BY u.name ASC`
  );

  return success(res, 'Daftar barber berhasil diambil', rows);
});

const getBarber = asyncHandler(async (req, res) => {
  const barber = await getBarberRow(Number(req.params.id));
  if (!barber) throw new ApiError(404, 'Barber tidak ditemukan');

  return success(res, 'Detail barber berhasil diambil', barber);
});

const getAvailability = asyncHandler(async (req, res) => {
  const barberId = Number(req.params.id);
  const { date, duration } = req.validatedQuery;
  const serviceDuration = duration || 30;

  const barber = await getBarberRow(barberId);
  if (!barber || barber.is_active !== 1) throw new ApiError(404, 'Barber tidak ditemukan atau nonaktif');

  const [bookings] = await pool.query(
    `SELECT start_time, end_time FROM bookings
     WHERE barber_id = ? AND booking_date = ? AND status <> 'cancelled'`,
    [barberId, date]
  );

  const workStart = toMinutes(barber.work_start);
  const workEnd = toMinutes(barber.work_end);
  const nowTime = currentTimeString();
  const isToday = date === todayString();
  const slots = [];

  // Slot dibuat per 30 menit dan harus selesai sebelum jam kerja berakhir
  for (let minute = workStart; minute + serviceDuration <= workEnd; minute += 30) {
    const slotStart = normalizeTime(`${String(Math.floor(minute / 60)).padStart(2, '0')}:${String(minute % 60).padStart(2, '0')}`);
    const slotEnd = addMinutes(slotStart, serviceDuration);

    if (isToday && toMinutes(slotStart) < toMinutes(nowTime)) continue;

    const conflict = bookings.some((booking) =>
      isOverlap(slotStart, slotEnd, booking.start_time, booking.end_time)
    );
    if (!conflict) slots.push(slotStart.slice(0, 5));
  }

  return success(res, 'Slot jadwal berhasil dihitung', {
    barber_id: barberId,
    date,
    work_start: barber.work_start,
    work_end: barber.work_end,
    duration_minutes: serviceDuration,
    slots,
  });
});

const createBarber = asyncHandler(async (req, res) => {
  const { name, email, phone, password, specialty, bio, work_start, work_end, is_active } =
    req.validatedBody;

  const [duplicate] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
  if (duplicate.length > 0) throw new ApiError(409, 'Email sudah terdaftar');

  let photo = { url: null, publicId: null };
  if (req.file) {
    photo = await uploadImage(req.file.buffer, 'barbers', req.file.mimetype);
  }

  const hashedPassword = await bcrypt.hash(password, 10);
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const [userResult] = await connection.query(
      'INSERT INTO users (name, email, phone, password, role) VALUES (?, ?, ?, ?, ?)',
      [name, email, phone || null, hashedPassword, 'barber']
    );

    const [barberResult] = await connection.query(
      `INSERT INTO barbers (user_id, specialty, bio, photo_url, photo_public_id, work_start, work_end, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userResult.insertId,
        specialty || null,
        bio || null,
        photo.url,
        photo.publicId,
        normalizeTime(work_start || '09:00'),
        normalizeTime(work_end || '21:00'),
        is_active === undefined ? 1 : is_active ? 1 : 0,
      ]
    );

    await connection.commit();

    const barber = await getBarberRow(barberResult.insertId);
    return success(res, 'Barber berhasil ditambahkan', barber, 201);
  } catch (error) {
    await connection.rollback();
    if (photo.publicId) await deleteImage(photo.publicId);
    throw error;
  } finally {
    connection.release();
  }
});

const updateBarber = asyncHandler(async (req, res) => {
  const barberId = Number(req.params.id);
  const current = await getBarberRow(barberId);
  if (!current) throw new ApiError(404, 'Barber tidak ditemukan');

  const body = req.validatedBody;
  const workStart = body.work_start ? normalizeTime(body.work_start) : current.work_start;
  const workEnd = body.work_end ? normalizeTime(body.work_end) : current.work_end;

  if (toMinutes(workEnd) <= toMinutes(workStart)) {
    throw new ApiError(400, 'Jam selesai harus lebih besar dari jam mulai');
  }

  if (body.email && body.email !== current.email) {
    const [duplicate] = await pool.query('SELECT id FROM users WHERE email = ? AND id <> ?', [
      body.email,
      current.user_id,
    ]);
    if (duplicate.length > 0) throw new ApiError(409, 'Email sudah terdaftar');
  }

  let uploaded = null;
  if (req.file) {
    uploaded = await uploadImage(req.file.buffer, 'barbers', req.file.mimetype);
  }

  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const userFields = [];
    const userValues = [];
    if (body.name !== undefined) {
      userFields.push('name = ?');
      userValues.push(body.name);
    }
    if (body.email !== undefined) {
      userFields.push('email = ?');
      userValues.push(body.email);
    }
    if (body.phone !== undefined) {
      userFields.push('phone = ?');
      userValues.push(body.phone || null);
    }
    if (userFields.length > 0) {
      userValues.push(current.user_id);
      await connection.query(`UPDATE users SET ${userFields.join(', ')} WHERE id = ?`, userValues);
    }

    const barberFields = [];
    const barberValues = [];
    if (body.specialty !== undefined) {
      barberFields.push('specialty = ?');
      barberValues.push(body.specialty || null);
    }
    if (body.bio !== undefined) {
      barberFields.push('bio = ?');
      barberValues.push(body.bio || null);
    }
    if (body.work_start !== undefined || body.work_end !== undefined) {
      barberFields.push('work_start = ?', 'work_end = ?');
      barberValues.push(workStart, workEnd);
    }
    if (body.is_active !== undefined) {
      barberFields.push('is_active = ?');
      barberValues.push(body.is_active ? 1 : 0);
    }
    if (uploaded) {
      barberFields.push('photo_url = ?', 'photo_public_id = ?');
      barberValues.push(uploaded.url, uploaded.publicId);
    }

    if (barberFields.length > 0) {
      barberValues.push(barberId);
      await connection.query(
        `UPDATE barbers SET ${barberFields.join(', ')} WHERE id = ?`,
        barberValues
      );
    }

    await connection.commit();
  } catch (error) {
    await connection.rollback();
    if (uploaded) await deleteImage(uploaded.publicId);
    throw error;
  } finally {
    connection.release();
  }

  if (uploaded && (current.photo_public_id || current.user_photo_public_id)) {
    await deleteImage(current.photo_public_id || current.user_photo_public_id);
  }

  const barber = await getBarberRow(barberId);
  return success(res, 'Data barber berhasil diperbarui', barber);
});

const deleteBarber = asyncHandler(async (req, res) => {
  const barberId = Number(req.params.id);
  const current = await getBarberRow(barberId);
  if (!current) throw new ApiError(404, 'Barber tidak ditemukan');

  const [usage] = await pool.query('SELECT COUNT(*) AS total FROM bookings WHERE barber_id = ?', [
    barberId,
  ]);
  if (usage[0].total > 0) {
    throw new ApiError(
      409,
      'Barber masih memiliki riwayat booking. Nonaktifkan akunnya agar riwayat tetap tersimpan'
    );
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await connection.query('DELETE FROM barbers WHERE id = ?', [barberId]);
    await connection.query('DELETE FROM users WHERE id = ?', [current.user_id]);
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }

  if (current.photo_public_id || current.user_photo_public_id) {
    await deleteImage(current.photo_public_id || current.user_photo_public_id);
  }

  return success(res, 'Barber berhasil dihapus');
});

module.exports = {
  listBarbers,
  getBarber,
  getAvailability,
  createBarber,
  updateBarber,
  deleteBarber,
};
