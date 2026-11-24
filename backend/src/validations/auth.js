const { z, emailField, passwordField, optionalText } = require('./helpers');

const registerBody = z.object({
  name: z.string({ required_error: 'Nama wajib diisi' }).trim().min(2, 'Nama minimal 2 karakter').max(100),
  email: emailField,
  phone: optionalText(20),
  password: passwordField,
});

const loginBody = z.object({
  email: emailField,
  password: z.string({ required_error: 'Password wajib diisi' }).min(1, 'Password wajib diisi'),
});

module.exports = { registerBody, loginBody };
