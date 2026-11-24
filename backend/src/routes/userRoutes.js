const router = require('express').Router();
const upload = require('../middlewares/upload');
const validateZod = require('../middlewares/validateZod');
const { verifyToken } = require('../middlewares/auth');
const { allowRoles } = require('../middlewares/role');
const { idParam } = require('../validations/helpers');
const { updateMeBody, updateUserBody } = require('../validations/user');
const {
  updateMe,
  uploadPhoto,
  listUsers,
  updateUser,
} = require('../controllers/userController');

router.use(verifyToken);

router.put('/me', validateZod({ body: updateMeBody }), updateMe);
router.post('/me/photo', upload.single('photo'), uploadPhoto);

router.get('/', allowRoles('admin'), listUsers);
router.patch(
  '/:id',
  allowRoles('admin'),
  validateZod({ params: idParam, body: updateUserBody }),
  updateUser
);

module.exports = router;
