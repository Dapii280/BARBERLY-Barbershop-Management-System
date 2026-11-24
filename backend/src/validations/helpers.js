const { z } = require('zod');
const { isValidDateString, isValidTimeString } = require('../utils/time');

const emptyToUndefined = (value) =>
  value === '' || value === null || value === undefined ? undefined : value;

const booleanFromInput = z.preprocess((value) => {
  if (value === undefined || value === null || value === '') return undefined;
  if (value === true || value === 'true' || value === 1 || value === '1') return true;
  if (value === false || value === 'false' || value === 0 || value === '0') return false;
  return value;
}, z.boolean());

const idParam = z.object({
  id: z.coerce.number().int().positive('ID tidak valid'),
});

const emailField = z
  .string({ required_error: 'Email wajib diisi' })
  .trim()
  .toLowerCase()
  .regex(/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'Format email tidak valid')
  .max(100, 'Email maksimal 100 karakter');

const passwordField = z
  .string({ required_error: 'Password wajib diisi' })
  .min(8, 'Password minimal 8 karakter')
  .max(72, 'Password maksimal 72 karakter');

const optionalText = (max) => z.preprocess(emptyToUndefined, z.string().trim().max(max).optional());

const dateField = z
  .string({ required_error: 'Tanggal wajib diisi' })
  .refine((value) => isValidDateString(value), 'Format tanggal harus YYYY-MM-DD');

const timeField = z
  .string({ required_error: 'Jam wajib diisi' })
  .refine((value) => isValidTimeString(value), 'Format jam harus HH:MM');

module.exports = {
  z,
  emptyToUndefined,
  booleanFromInput,
  idParam,
  emailField,
  passwordField,
  optionalText,
  dateField,
  timeField,
};
