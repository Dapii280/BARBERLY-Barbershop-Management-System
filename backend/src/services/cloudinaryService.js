const fs = require('fs/promises');
const path = require('path');
const crypto = require('crypto');
const { cloudinary, isCloudinaryConfigured } = require('../config/cloudinary');

const PUBLIC_DIR = path.join(__dirname, '..', '..', 'public', 'uploads');

const extensionFromMime = (mimetype = 'image/jpeg') => {
  const type = mimetype.split('/')[1] || 'jpeg';
  return type === 'jpeg' ? 'jpg' : type;
};

/**
 * Upload gambar ke folder barberly/<folder>.
 * Bila kredensial Cloudinary belum diisi, file disimpan di public/uploads/<folder>
 * agar project tetap bisa dijalankan tanpa akun Cloudinary.
 */
const uploadImage = async (buffer, folder, mimetype = 'image/jpeg') => {
  if (isCloudinaryConfigured()) {
    return new Promise((resolve, reject) => {
      const stream = cloudinary.uploader.upload_stream(
        { folder: `barberly/${folder}`, resource_type: 'image' },
        (error, result) => {
          if (error) return reject(error);
          return resolve({ url: result.secure_url, publicId: result.public_id });
        }
      );
      stream.end(buffer);
    });
  }

  const filename = `${Date.now()}-${crypto.randomBytes(4).toString('hex')}.${extensionFromMime(mimetype)}`;
  const directory = path.join(PUBLIC_DIR, folder);
  await fs.mkdir(directory, { recursive: true });
  await fs.writeFile(path.join(directory, filename), buffer);

  const baseUrl = (process.env.APP_BASE_URL || `http://localhost:${process.env.PORT || 5000}`).replace(
    /\/$/,
    ''
  );

  return {
    url: `${baseUrl}/uploads/${folder}/${filename}`,
    publicId: `local:${folder}/${filename}`,
  };
};

const deleteImage = async (publicId) => {
  if (!publicId) return;

  // Gambar hasil penyimpanan lokal
  if (String(publicId).startsWith('local:')) {
    const relativePath = String(publicId).slice('local:'.length);
    const filePath = path.join(PUBLIC_DIR, relativePath);
    try {
      await fs.unlink(filePath);
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
    return;
  }

  if (isCloudinaryConfigured()) {
    await cloudinary.uploader.destroy(publicId);
  }
};

module.exports = { uploadImage, deleteImage };
