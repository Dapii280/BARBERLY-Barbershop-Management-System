const pool = require('../config/db');
const { success } = require('../utils/response');
const { ApiError, asyncHandler } = require('../utils/asyncHandler');
const { uploadImage, deleteImage } = require('../services/cloudinaryService');

const SERVICE_COLUMNS =
  'id, name, description, price, duration_minutes, image_url, image_public_id, is_active';

const listServices = asyncHandler(async (req, res) => {
  // Admin dapat meminta seluruh data (termasuk nonaktif) dengan ?all=1
  const showAll = String(req.query.all || '') === '1' && req.user.role === 'admin';
  const [rows] = await pool.query(
    `SELECT ${SERVICE_COLUMNS} FROM services ${showAll ? '' : 'WHERE is_active = 1'} ORDER BY id ASC`
  );

  return success(res, 'Daftar layanan berhasil diambil', rows);
});

const getService = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const [rows] = await pool.query(`SELECT ${SERVICE_COLUMNS} FROM services WHERE id = ?`, [id]);
  if (rows.length === 0) throw new ApiError(404, 'Layanan tidak ditemukan');

  return success(res, 'Detail layanan berhasil diambil', rows[0]);
});

const createService = asyncHandler(async (req, res) => {
  const { name, description, price, duration_minutes, is_active } = req.validatedBody;

  let image = { url: null, publicId: null };
  if (req.file) {
    image = await uploadImage(req.file.buffer, 'services', req.file.mimetype);
  }

  const [result] = await pool.query(
    `INSERT INTO services (name, description, price, duration_minutes, image_url, image_public_id, is_active)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      name,
      description || null,
      price,
      duration_minutes,
      image.url,
      image.publicId,
      is_active === undefined ? 1 : is_active ? 1 : 0,
    ]
  );

  const [rows] = await pool.query(`SELECT ${SERVICE_COLUMNS} FROM services WHERE id = ?`, [
    result.insertId,
  ]);

  return success(res, 'Layanan berhasil ditambahkan', rows[0], 201);
});

const updateService = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const [rows] = await pool.query(`SELECT ${SERVICE_COLUMNS} FROM services WHERE id = ?`, [id]);
  if (rows.length === 0) throw new ApiError(404, 'Layanan tidak ditemukan');

  const current = rows[0];
  const body = req.validatedBody;

  let imageUrl = current.image_url;
  let imagePublicId = current.image_public_id;

  if (req.file) {
    const uploaded = await uploadImage(req.file.buffer, 'services', req.file.mimetype);
    imageUrl = uploaded.url;
    imagePublicId = uploaded.publicId;
  }

  const fields = [];
  const values = [];

  const assign = (column, value) => {
    fields.push(`${column} = ?`);
    values.push(value);
  };

  if (body.name !== undefined) assign('name', body.name);
  if (body.description !== undefined) assign('description', body.description || null);
  if (body.price !== undefined) assign('price', body.price);
  if (body.duration_minutes !== undefined) assign('duration_minutes', body.duration_minutes);
  if (body.is_active !== undefined) assign('is_active', body.is_active ? 1 : 0);

  // Gambar baru selalu disimpan, gambar lama dihapus setelah update sukses
  if (req.file) {
    assign('image_url', imageUrl);
    assign('image_public_id', imagePublicId);
  }

  if (fields.length === 0) throw new ApiError(400, 'Tidak ada data yang diubah');

  values.push(id);
  await pool.query(`UPDATE services SET ${fields.join(', ')} WHERE id = ?`, values);

  if (req.file && current.image_public_id) {
    await deleteImage(current.image_public_id);
  }

  const [updated] = await pool.query(`SELECT ${SERVICE_COLUMNS} FROM services WHERE id = ?`, [id]);
  return success(res, 'Layanan berhasil diperbarui', updated[0]);
});

const deleteService = asyncHandler(async (req, res) => {
  const id = Number(req.params.id);

  const [rows] = await pool.query(`SELECT ${SERVICE_COLUMNS} FROM services WHERE id = ?`, [id]);
  if (rows.length === 0) throw new ApiError(404, 'Layanan tidak ditemukan');

  const [usage] = await pool.query('SELECT COUNT(*) AS total FROM booking_items WHERE service_id = ?', [
    id,
  ]);
  if (usage[0].total > 0) {
    throw new ApiError(
      409,
      'Layanan sudah dipakai pada booking, nonaktifkan saja agar riwayat transaksi tetap utuh'
    );
  }

  await pool.query('DELETE FROM services WHERE id = ?', [id]);
  await deleteImage(rows[0].image_public_id);

  return success(res, 'Layanan berhasil dihapus');
});

module.exports = { listServices, getService, createService, updateService, deleteService };
