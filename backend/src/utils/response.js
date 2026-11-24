// Format respons API yang konsisten
const success = (res, message, data = null, statusCode = 200) =>
  res.status(statusCode).json({ success: true, message, data });

const failure = (res, message, statusCode = 400, errors = null) =>
  res.status(statusCode).json({
    success: false,
    message,
    data: null,
    ...(errors ? { errors } : {}),
  });

module.exports = { success, failure };
