const router = require('express').Router();
const upload = require('../middlewares/upload');
const validateZod = require('../middlewares/validateZod');
const { verifyToken } = require('../middlewares/auth');
const { allowRoles } = require('../middlewares/role');
const { idParam } = require('../validations/helpers');
const { createServiceBody, updateServiceBody } = require('../validations/service');
const {
  listServices,
  getService,
  createService,
  updateService,
  deleteService,
} = require('../controllers/serviceController');

router.use(verifyToken);

router.get('/', listServices);
router.get('/:id', validateZod({ params: idParam }), getService);

router.post(
  '/',
  allowRoles('admin'),
  upload.single('image'),
  validateZod({ body: createServiceBody }),
  createService
);

router.put(
  '/:id',
  allowRoles('admin'),
  upload.single('image'),
  validateZod({ params: idParam, body: updateServiceBody }),
  updateService
);

router.delete('/:id', allowRoles('admin'), validateZod({ params: idParam }), deleteService);

module.exports = router;
