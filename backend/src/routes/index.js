const router = require('express').Router();

router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Barberly API aktif',
    data: { uptime: process.uptime(), timestamp: new Date().toISOString() },
  });
});

router.use('/auth', require('./authRoutes'));
router.use('/users', require('./userRoutes'));
router.use('/services', require('./serviceRoutes'));
router.use('/barbers', require('./barberRoutes'));
router.use('/bookings', require('./bookingRoutes'));
router.use('/transactions', require('./transactionRoutes'));
router.use('/dashboard', require('./dashboardRoutes'));

module.exports = router;
