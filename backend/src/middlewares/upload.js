const multer = require('multer');

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

// File disimpan di memori lalu diunggah ke Cloudinary / penyimpanan lokal
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024 },
  fileFilter: (req, file, callback) => {
    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      return callback(
        new multer.MulterError('LIMIT_UNEXPECTED_FILE', 'File harus berupa gambar JPG, PNG, atau WEBP')
      );
    }
    return callback(null, true);
  },
});

module.exports = upload;
