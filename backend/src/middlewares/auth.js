const jwt = require('jsonwebtoken');
const pool = require('../config/db');

// Verifikasi Bearer JWT lalu tempelkan data user terbaru ke req.user
const verifyToken = async (req, res, next) => {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Token akses tidak ditemukan',
      data: null,
    });
  }

  const token = header.slice(7).trim();

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const [rows] = await pool.query(
      'SELECT id, name, email, phone, role, photo_url, is_active FROM users WHERE id = ?',
      [payload.id]
    );

    if (rows.length === 0 || rows[0].is_active !== 1) {
      return res.status(401).json({
        success: false,
        message: 'Akun tidak ditemukan atau sudah dinonaktifkan',
        data: null,
      });
    }

    req.user = rows[0];
    return next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Token tidak valid atau sudah kedaluwarsa',
      data: null,
    });
  }
};

module.exports = { verifyToken };
