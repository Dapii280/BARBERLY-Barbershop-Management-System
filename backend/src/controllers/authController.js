const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const { success } = require('../utils/response');
const { ApiError, asyncHandler } = require('../utils/asyncHandler');

const USER_COLUMNS = 'id, name, email, phone, role, photo_url, is_active, created_at';

const signToken = (user) =>
  jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });

const register = asyncHandler(async (req, res) => {
  const { name, email, phone, password } = req.validatedBody;

  const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
  if (existing.length > 0) {
    throw new ApiError(409, 'Email sudah terdaftar');
  }

  const hashedPassword = await bcrypt.hash(password, 10);
  const [result] = await pool.query(
    'INSERT INTO users (name, email, phone, password, role) VALUES (?, ?, ?, ?, ?)',
    [name, email, phone || null, hashedPassword, 'customer']
  );

  const [rows] = await pool.query(`SELECT ${USER_COLUMNS} FROM users WHERE id = ?`, [
    result.insertId,
  ]);

  return success(res, 'Registrasi berhasil', rows[0], 201);
});

const login = asyncHandler(async (req, res) => {
  const { email, password } = req.validatedBody;

  const [rows] = await pool.query(
    `SELECT ${USER_COLUMNS}, password FROM users WHERE email = ?`,
    [email]
  );
  const user = rows[0];

  // Pesan disamakan agar tidak membocorkan email mana yang terdaftar
  if (!user) throw new ApiError(401, 'Email atau password salah');
  if (user.is_active !== 1) throw new ApiError(403, 'Akun Anda sedang dinonaktifkan');

  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) throw new ApiError(401, 'Email atau password salah');

  delete user.password;
  const token = signToken(user);

  return success(res, 'Login berhasil', { token, user });
});

const me = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(`SELECT ${USER_COLUMNS} FROM users WHERE id = ?`, [req.user.id]);
  if (rows.length === 0) throw new ApiError(404, 'User tidak ditemukan');

  let barber = null;
  if (rows[0].role === 'barber') {
    const [barberRows] = await pool.query(
      'SELECT id, specialty, bio, work_start, work_end FROM barbers WHERE user_id = ?',
      [req.user.id]
    );
    barber = barberRows[0] || null;
  }

  return success(res, 'Profil berhasil diambil', { ...rows[0], barber });
});

module.exports = { register, login, me };
