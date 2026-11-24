const {
  z,
  emailField,
  passwordField,
  optionalText,
  booleanFromInput,
  emptyToUndefined,
  dateField,
} = require('./helpers');
const { toMinutes } = require('../utils/time');

const workTime = z.preprocess(
  emptyToUndefined,
  z.string().regex(/^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/, 'Format jam harus HH:MM').optional()
);

const createBarberBody = z
  .object({
    name: z.string().trim().min(2, 'Nama minimal 2 karakter').max(100),
    email: emailField,
    phone: optionalText(20),
    password: passwordField,
    specialty: optionalText(100),
    bio: optionalText(1000),
    work_start: workTime.default('09:00'),
    work_end: workTime.default('21:00'),
    is_active: booleanFromInput.optional(),
  })
  .refine(
    (data) => toMinutes(data.work_end || '21:00') > toMinutes(data.work_start || '09:00'),
    { message: 'Jam selesai harus lebih besar dari jam mulai', path: ['work_end'] }
  );

const updateBarberBody = z
  .object({
    name: z.preprocess(emptyToUndefined, z.string().trim().min(2).max(100).optional()),
    email: z.preprocess(emptyToUndefined, emailField.optional()),
    phone: optionalText(20),
    specialty: optionalText(100),
    bio: optionalText(1000),
    work_start: workTime,
    work_end: workTime,
    is_active: booleanFromInput.optional(),
  })
  .refine((data) => Object.keys(data).length > 0, { message: 'Tidak ada data yang diubah' })
  .refine(
    (data) =>
      !data.work_start || !data.work_end || toMinutes(data.work_end) > toMinutes(data.work_start),
    { message: 'Jam selesai harus lebih besar dari jam mulai', path: ['work_end'] }
  );

const availabilityQuery = z.object({
  date: dateField,
  duration: z.preprocess(
    emptyToUndefined,
    z.coerce.number().int().positive().max(600).optional()
  ),
});

module.exports = { createBarberBody, updateBarberBody, availabilityQuery };
