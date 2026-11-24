const { z, optionalText, booleanFromInput, emptyToUndefined } = require('./helpers');

const updateMeBody = z
  .object({
    name: z.preprocess(emptyToUndefined, z.string().trim().min(2, 'Nama minimal 2 karakter').max(100).optional()),
    phone: optionalText(20),
    password: z.preprocess(
      emptyToUndefined,
      z.string().min(8, 'Password baru minimal 8 karakter').max(72).optional()
    ),
    current_password: optionalText(72),
  })
  .refine((data) => !data.password || Boolean(data.current_password), {
    message: 'Password saat ini wajib diisi untuk mengganti password',
    path: ['current_password'],
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'Tidak ada data yang diubah',
  });

const updateUserBody = z
  .object({
    role: z.preprocess(emptyToUndefined, z.enum(['admin', 'barber', 'customer']).optional()),
    is_active: booleanFromInput.optional(),
  })
  .refine((data) => data.role !== undefined || data.is_active !== undefined, {
    message: 'Isi role atau status aktif',
  });

module.exports = { updateMeBody, updateUserBody };
