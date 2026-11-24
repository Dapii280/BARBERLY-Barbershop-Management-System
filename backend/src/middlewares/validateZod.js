const { ZodError } = require('zod');

// Validasi body / params / query dengan skema Zod
const validateZod = (schemas) => (req, res, next) => {
  try {
    if (schemas.body) req.validatedBody = schemas.body.parse(req.body ?? {});
    if (schemas.params) req.validatedParams = schemas.params.parse(req.params ?? {});
    if (schemas.query) req.validatedQuery = schemas.query.parse(req.query ?? {});
    return next();
  } catch (error) {
    const isZodError = error instanceof ZodError || error?.name === 'ZodError';

    if (isZodError) {
      const errors = (error.issues || []).map((issue) => ({
        field: issue.path.length > 0 ? issue.path.join('.') : 'body',
        message: issue.message,
      }));

      return res.status(400).json({
        success: false,
        message: 'Data yang dikirim tidak valid',
        data: null,
        errors,
      });
    }

    return next(error);
  }
};

module.exports = validateZod;
