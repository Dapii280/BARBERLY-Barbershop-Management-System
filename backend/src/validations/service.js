const { z, optionalText, booleanFromInput, emptyToUndefined } = require('./helpers');

const numberField = (message) =>
  z.preprocess(emptyToUndefined, z.coerce.number({ message }).positive(message));

const createServiceBody = z.object({
  name: z.string().trim().min(2, 'Nama layanan minimal 2 karakter').max(100),
  description: optionalText(1000),
  price: numberField('Harga harus lebih dari 0'),
  duration_minutes: z.preprocess(
    emptyToUndefined,
    z.coerce
      .number({ message: 'Durasi harus berupa angka' })
      .int('Durasi harus bilangan bulat')
      .positive('Durasi harus lebih dari 0')
      .max(600, 'Durasi maksimal 600 menit')
  ),
  is_active: booleanFromInput.optional(),
});

const updateServiceBody = z
  .object({
    name: z.preprocess(emptyToUndefined, z.string().trim().min(2).max(100).optional()),
    description: optionalText(1000),
    price: z.preprocess(emptyToUndefined, z.coerce.number().positive('Harga harus lebih dari 0').optional()),
    duration_minutes: z.preprocess(
      emptyToUndefined,
      z.coerce.number().int().positive().max(600).optional()
    ),
    is_active: booleanFromInput.optional(),
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'Tidak ada data yang diubah' });

module.exports = { createServiceBody, updateServiceBody };
