const router = require('express').Router();
const upload = require('../middlewares/upload');
const validateZod = require('../middlewares/validateZod');
const { verifyToken } = require('../middlewares/auth');
const { allowRoles } = require('../middlewares/role');
const { idParam } = require('../validations/helpers');
const {
  createBookingBody,
  listBookingQuery,
  updateStatusBody,
} = require('../validations/booking');
const { paymentBody } = require('../validations/transaction');
const {
  listBookings,
  getBooking,
  createBooking,
  cancelBooking,
  updateBookingStatus,
} = require('../controllers/bookingController');
const { createPayment, createCashPayment } = require('../controllers/transactionController');

router.use(verifyToken);

router.get('/', validateZod({ query: listBookingQuery }), listBookings);
router.get('/:id', validateZod({ params: idParam }), getBooking);
router.post(
  '/',
  allowRoles('customer'),
  validateZod({ body: createBookingBody }),
  createBooking
);

router.patch(
  '/:id/cancel',
  allowRoles('customer', 'admin'),
  validateZod({ params: idParam }),
  cancelBooking
);
router.patch(
  '/:id/status',
  allowRoles('barber', 'admin'),
  validateZod({ params: idParam, body: updateStatusBody }),
  updateBookingStatus
);

// Pembayaran melekat pada booking (prefix /api/v1/bookings)
router.post(
  '/:id/payment',
  allowRoles('customer'),
  upload.single('proof'),
  validateZod({ params: idParam, body: paymentBody }),
  createPayment
);
router.post(
  '/:id/cash',
  allowRoles('admin'),
  validateZod({ params: idParam }),
  createCashPayment
);

module.exports = router;
