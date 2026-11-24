const router = require('express').Router();
const upload = require('../middlewares/upload');
const validateZod = require('../middlewares/validateZod');
const { verifyToken } = require('../middlewares/auth');
const { allowRoles } = require('../middlewares/role');
const { idParam } = require('../validations/helpers');
const {
  createBarberBody,
  updateBarberBody,
  availabilityQuery,
} = require('../validations/barber');
const {
  listBarbers,
  getBarber,
  getAvailability,
  createBarber,
  updateBarber,
  deleteBarber,
} = require('../controllers/barberController');

router.use(verifyToken);

router.get('/', listBarbers);
router.get('/:id', validateZod({ params: idParam }), getBarber);
router.get(
  '/:id/availability',
  validateZod({ params: idParam, query: availabilityQuery }),
  getAvailability
);

router.post(
  '/',
  allowRoles('admin'),
  upload.single('photo'),
  validateZod({ body: createBarberBody }),
  createBarber
);

router.put(
  '/:id',
  allowRoles('admin'),
  upload.single('photo'),
  validateZod({ params: idParam, body: updateBarberBody }),
  updateBarber
);

router.delete('/:id', allowRoles('admin'), validateZod({ params: idParam }), deleteBarber);

module.exports = router;
