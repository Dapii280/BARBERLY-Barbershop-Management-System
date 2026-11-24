// Role Based Access Control sederhana
const allowRoles =
  (...roles) =>
  (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Anda tidak memiliki akses untuk aksi ini',
        data: null,
      });
    }
    return next();
  };

module.exports = { allowRoles };
