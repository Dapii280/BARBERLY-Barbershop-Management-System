const { z, emptyToUndefined } = require('./helpers');

const paymentBody = z.object({
  payment_method: z.preprocess(
    emptyToUndefined,
    z.enum(['transfer', 'ewallet']).default('transfer')
  ),
});

const listTransactionQuery = z.object({
  payment_status: z.preprocess(
    emptyToUndefined,
    z.enum(['waiting', 'paid', 'rejected']).optional()
  ),
});

const verifyBody = z.object({
  payment_status: z.enum(['paid', 'rejected'], {
    message: 'Status verifikasi hanya paid atau rejected',
  }),
  note: z.preprocess(emptyToUndefined, z.string().trim().max(255).optional()),
});

module.exports = { paymentBody, listTransactionQuery, verifyBody };
