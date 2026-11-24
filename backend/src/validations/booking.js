const { z, emptyToUndefined, dateField, timeField, optionalText } = require('./helpers');

const BOOKING_STATUSES = ['pending', 'confirmed', 'completed', 'cancelled'];

const serviceIdsField = z.preprocess((value) => {
  if (typeof value === 'string') {
    return value
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);
  }
  if (typeof value === 'number') return [value];
  return value;
}, z.array(z.coerce.number().int().positive()).min(1, 'Pilih minimal satu layanan'));

const createBookingBody = z.object({
  barber_id: z.coerce.number().int().positive('Barber tidak valid'),
  booking_date: dateField,
  start_time: timeField,
  service_ids: serviceIdsField,
  notes: optionalText(500),
});

const listBookingQuery = z.object({
  date: z.preprocess(emptyToUndefined, dateField.optional()),
  barber_id: z.preprocess(emptyToUndefined, z.coerce.number().int().positive().optional()),
  status: z.preprocess(emptyToUndefined, z.enum(BOOKING_STATUSES).optional()),
});

const updateStatusBody = z.object({
  status: z.enum(['confirmed', 'completed'], {
    message: 'Status hanya boleh confirmed atau completed',
  }),
});

module.exports = {
  BOOKING_STATUSES,
  createBookingBody,
  listBookingQuery,
  updateStatusBody,
};
