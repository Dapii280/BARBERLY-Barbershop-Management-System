const bcrypt = require('bcrypt');
const pool = require('../config/db');
const { success } = require('../utils/response');
const { ApiError, asyncHandler } = require('../utils/asyncHandler');
const { uploadImage, deleteImage } = require('../services/cloudinaryService');

const USER_COLUMNS = 'id, name, email, phone, role, photo_url, is_active, created_at';

const updateMe = asyncHandler(async (req, res) => {
  const { name, phone, password, current_password } = req.validatedBody;

  const [rows] = await pool.query('SELECT id, password FROM users WHERE id = ?', [req.user.id]);
  if (rows.length === 0) throw new ApiError(404, 'User tidak ditemukan');

  const fields = [];
  const values = [];

  if (name !== undefined) {
    fields.push('name = ?');
    values.push(name);
  }

  if (phone !== undefined) {
    fields.push('phone = ?');
    values.push(phone || null);
  }

  if (password) {
    const isMatch = await bcrypt.compare(current_password, rows[0].password);
    if (!isMatch) throw new ApiError(400, 'Password saat ini salah');

    const hashedPassword = await bcrypt.hash(password, 10);
    fields.push('password = ?');
    values.push(hashedPassword);
  }

  if (fields.length === 0) throw new ApiError(400, 'Tidak ada data yang diubah');

  values.push(req.user.id);
  await pool.query(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`, values);

  const [updated] = await pool.query(`SELECT ${USER_COLUMNS} FROM users WHERE id = ?`, [
    req.user.id,
  ]);

  return success(res, 'Profil berhasil diperbarui', updated[0]);
});

const uploadPhoto = asyncHandler(async (req, res) => {
  if (!req.file) throw new ApiError(400, 'File foto wajib diunggah');

  const [rows] = await pool.query('SELECT photo_url, photo_public_id FROM users WHERE id = ?', [
    req.user.id,
  ]);
  if (rows.length === 0) throw new ApiError(404, 'User tidak ditemukan');

  const uploaded = await uploadImage(req.file.buffer, 'profiles', req.file.mimetype);

  await pool.query('UPDATE users SET photo_url = ?, photo_public_id = ? WHERE id = ?', [
    uploaded.url,
    uploaded.publicId,
    req.user.id,
  ]);

  // Hapus foto lama setelah foto baru tersimpan
  if (rows[0].photo_public_id) {
    await deleteImage(rows[0].photo_public_id);
  }

  const [updated] = await pool.query(`SELECT ${USER_COLUMNS} FROM users WHERE id = ?`, [
    req.user.id,
  ]);

  return success(res, 'Foto profil berhasil diperbarui', updated[0]);
});

const listUsers = asyncHandler(async (req, res) => {
  const [rows] = await pool.query(`SELECT ${USER_COLUMNS} FROM users ORDER BY id ASC`);
  return success(res, 'Daftar pengguna berhasil diambil', rows);
});

const updateUser = asyncHandler(async (req, res) => {
  const targetId = req.validatedParams?.id ?? Number(req.params.id);
  const { role, is_active } = req.validatedBody;

  if (targetId === req.user.id && (role !== undefined || is_active === 0 || is_active === false)) {
    throw new ApiError(400, 'Anda tidak dapat mengubah role atau menonaktifkan akun sendiri');
  }

  const [rows] = await pool.query('SELECT id, role FROM users WHERE id = ?', [targetId]);
  if (rows.length === 0) throw new ApiError(404, 'User tidak ditemukan');

  const fields = [];
  const values = [];

  if (role !== undefined) {
    fields.push('role = ?');
    values.push(role);
  }
  if (is_active !== undefined) {
    fields.push('is_active = ?');
    values.push(is_active ? 1 : 0);
  }

  values.push(targetId);
  await pool.query(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`, values);

  const [updated] = await pool.query(`SELECT ${USER_COLUMNS} FROM users WHERE id = ?`, [targetId]);
  return success(res, 'Data pengguna berhasil diperbarui', updated[0]);
});

module.exports = { updateMe, uploadPhoto, listUsers, updateUser };
