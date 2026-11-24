const multer = require('multer');

const notFound = (req, res) => {
  res.status(404).json({
    success: false,
    message: `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan`,
    data: null,
  });
};

// Error handler global: selalu JSON konsisten, stack trace tidak dibocorkan
// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Terjadi kesalahan pada server';
  let errors = err.details || null;

  if (err instanceof multer.MulterError) {
    statusCode = 400;
    if (err.code === 'LIMIT_FILE_SIZE') message = 'Ukuran file maksimal 2MB';
    if (err.code === 'LIMIT_UNEXPECTED_FILE' && err.field === 'photo') {
      message = 'Field upload tidak sesuai (gunakan nama field yang benar)';
    }
  }

  if (err.code === 'ER_DUP_ENTRY') {
    statusCode = 409;
    message = 'Data sudah digunakan, silakan pakai nilai lain';
  }

  if (err.code === 'ER_ROW_IS_REFERENCED_2') {
    statusCode = 409;
    message = 'Data masih dipakai pada transaksi lain';
  }

  if (err.type === 'entity.too.large') {
    statusCode = 413;
    message = 'Ukuran data terlalu besar';
  }

  if (err.type === 'entity.parse.failed') {
    statusCode = 400;
    message = 'Format JSON tidak valid';
  }

  if (statusCode >= 500) {
    console.error('[SERVER ERROR]', err);
    message = 'Terjadi kesalahan pada server';
    errors = null;
  }

  res.status(statusCode).json({
    success: false,
    message,
    data: null,
    ...(errors ? { errors } : {}),
  });
};

module.exports = { notFound, errorHandler };
