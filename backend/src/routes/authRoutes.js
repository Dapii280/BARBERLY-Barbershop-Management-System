const router = require('express').Router();
const validateZod = require('../middlewares/validateZod');
const { verifyToken } = require('../middlewares/auth');
const { registerBody, loginBody } = require('../validations/auth');
const { register, login, me } = require('../controllers/authController');

router.post('/register', validateZod({ body: registerBody }), register);
router.post('/login', validateZod({ body: loginBody }), login);
router.get('/me', verifyToken, me);

module.exports = router;
